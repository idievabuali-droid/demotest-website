const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const respond = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    ...corsHeaders,
  },
  body: JSON.stringify(body),
});

const ORDER_STATUS_VALUES = ['open', 'confirmed', 'shipped', 'cancelled'];
const INVENTORY_BASE_KEY = '__base__';

const parseBearerToken = (headers) => {
  const raw =
    headers?.authorization ||
    headers?.Authorization ||
    headers?.AUTHORIZATION ||
    '';
  const value = String(raw).trim();
  if (!value) return null;
  const match = value.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
};

const normalizeInventory = (raw) => {
  if (!raw || typeof raw !== 'object') return {};
  const result = {};
  Object.entries(raw).forEach(([key, value]) => {
    const numeric = Number(value);
    if (Number.isFinite(numeric) && numeric >= 0) {
      result[(key && key.trim()) || INVENTORY_BASE_KEY] = numeric;
    }
  });
  return result;
};

const normaliseStatus = (value) => {
  if (!value) return null;
  return String(value).toLowerCase();
};

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        ...corsHeaders,
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
      },
      body: '',
    };
  }

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return respond(500, { error: 'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars.' });
  }

  let supabase;
  try {
    supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    });
  } catch (error) {
    console.error('Supabase client init failed', error);
    return respond(500, { error: 'Failed to initialise Supabase client.' });
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return respond(400, { error: 'Request body must be valid JSON.' });
  }

  const { action, data } = payload || {};
  if (!action) {
    return respond(400, { error: 'Missing action.' });
  }

  try {
    const ownerOnlyActions = new Set(['insert', 'upsert', 'delete', 'listOrders', 'updateOrderStatus']);
    if (ownerOnlyActions.has(action)) {
      const token = parseBearerToken(event.headers);
      if (!token) {
        return respond(401, { error: 'Missing Authorization bearer token.' });
      }

      const { data: userData, error: userError } = await supabase.auth.getUser(token);
      if (userError || !userData?.user?.id) {
        return respond(401, { error: 'Invalid or expired session.' });
      }

      const userId = userData.user.id;
      const { data: ownerRow, error: ownerError } = await supabase
        .from('owner_users')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();

      if (ownerError) {
        console.error('Owner lookup failed', ownerError);
        return respond(500, { error: 'Owner verification failed.' });
      }

      if (!ownerRow?.user_id) {
        return respond(403, { error: 'Not authorized.' });
      }
    }

    if (action === 'listOrders') {
      const { data: orders, error, status } = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', { ascending: false });

      if (error) {
        if (
          error.message &&
          (error.message.includes('relation \"orders\"') || error.message.includes('relation \"order_items\"'))
        ) {
          return respond(200, {
            data: [],
            meta: {
              missingOrdersTable: true,
              message: error.message,
            },
          });
        }
        throw error;
      }

      return respond(status || 200, { data: orders || [] });
    }

    if (action === 'updateOrderStatus') {
      const { id, status: rawStatus } = data || {};
      const nextStatus = normaliseStatus(rawStatus);

      if (!id || !nextStatus) {
        return respond(400, { error: 'Missing order id or status.' });
      }

      if (!ORDER_STATUS_VALUES.includes(nextStatus)) {
        return respond(400, { error: `Unsupported status \"${rawStatus}\".` });
      }

      const { data: updated, error } = await supabase
        .from('orders')
        .update({ status: nextStatus })
        .eq('id', id)
        .select('*, order_items(*)')
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          return respond(404, { error: `Order \"${id}\" not found.` });
        }
        throw error;
      }

      return respond(200, { data: updated, meta: { status: nextStatus } });
    }

    if (action === 'createOrder') {
      const payloadData = data || {};
      const items = Array.isArray(payloadData.items)
        ? payloadData.items.filter((item) => item && item.product_id && Number(item.quantity) > 0)
        : [];

      const subtotalCents = Number.isFinite(payloadData.subtotal_cents)
        ? Math.max(0, Math.round(payloadData.subtotal_cents))
        : items.reduce((sum, item) => sum + (Number(item.subtotal_cents) || 0), 0);
      const currency =
        typeof payloadData.currency === 'string' && payloadData.currency.trim()
          ? payloadData.currency.trim().toUpperCase()
          : 'GBP';

      const orderInsert = {
        customer_email: payloadData.customer_email || payloadData.customer?.email || null,
        customer_name: payloadData.customer_name || payloadData.customer?.name || null,
        status: 'open',
        total_cents: subtotalCents,
        currency,
        note: payloadData.notes || null,
        metadata: payloadData.metadata || {},
      };

      const { data: order, error: orderError } = await supabase.from('orders').insert([orderInsert]).select().single();
      if (orderError) throw orderError;

      if (items.length) {
        const itemRows = items.map((item) => ({
          order_id: order.id,
          product_id: item.product_id,
          sku: item.sku || null,
          name: item.name || null,
          quantity: Number(item.quantity) || 0,
          unit_price_cents: Number(item.unit_price_cents) || 0,
          subtotal_cents: Number(item.subtotal_cents) || 0,
          variants: item.variants || {},
          inventory_key: item.inventory_key || INVENTORY_BASE_KEY,
        }));

        const { error: itemsError } = await supabase.from('order_items').insert(itemRows);
        if (itemsError) throw itemsError;

        for (const row of itemRows) {
          if (!row.product_id || !(row.quantity > 0)) continue;
          try {
            const { data: productData, error: productError } = await supabase
              .from('products')
              .select('inventory')
              .eq('id', row.product_id)
              .single();

            if (productError) {
              console.error('Failed to fetch product inventory', productError);
              continue;
            }

            const currentInventory = normalizeInventory(productData?.inventory);
            if (Object.prototype.hasOwnProperty.call(currentInventory, row.inventory_key)) {
              currentInventory[row.inventory_key] = Math.max(
                0,
                Number(currentInventory[row.inventory_key]) - row.quantity,
              );
              const { error: updateError } = await supabase
                .from('products')
                .update({ inventory: currentInventory })
                .eq('id', row.product_id);

              if (updateError) {
                console.error('Failed to update product inventory', updateError);
              }
            }
          } catch (inventoryError) {
            console.error('Inventory adjustment failed', inventoryError);
          }
        }
      }

      return respond(200, { data: { id: order.id } });
    }

    if (action === 'insert') {
      const { data: inserted, error } = await supabase.from('products').insert([data]).select().single();
      if (error) throw error;
      return respond(200, { data: inserted });
    }

    if (action === 'upsert') {
      const { data: upserted, error } = await supabase.from('products').upsert([data], { onConflict: 'id' }).select().single();
      if (error) throw error;
      return respond(200, { data: upserted });
    }

    if (action === 'delete') {
      const { error } = await supabase.from('products').delete().eq('id', data?.id);
      if (error) throw error;
      return respond(200, { success: true });
    }

    return respond(400, { error: `Unsupported action \"${action}\".` });
  } catch (error) {
    console.error(`Supabase ${action} failed`, error);
    return respond(500, { error: error.message || 'Supabase operation failed.' });
  }
};
