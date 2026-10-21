-- Apply as a MariaDB administrator after creating the application account in
-- phpMyAdmin. Create it for host 127.0.0.1 and use the same account in .env.
-- This account is for the local Node API only; never put its credentials in
-- frontend code. Review the exact grants for your deployment before use.

GRANT SELECT ON controle_estoque_local.* TO 'estoque_app'@'127.0.0.1';

GRANT INSERT (id, inventory_id, created_by, name, unit, code, notes)
  ON controle_estoque_local.products TO 'estoque_app'@'127.0.0.1';
GRANT UPDATE (name, notes, grams_per_unit)
  ON controle_estoque_local.products TO 'estoque_app'@'127.0.0.1';

GRANT INSERT, DELETE ON controle_estoque_local.user_sessions
  TO 'estoque_app'@'127.0.0.1';

GRANT EXECUTE ON PROCEDURE controle_estoque_local.register_user
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.append_movement
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.set_inventory_role
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.set_product_active
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.set_product_cancelled
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.finalize_inventory_product
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.save_recipe
  TO 'estoque_app'@'127.0.0.1';
GRANT EXECUTE ON PROCEDURE controle_estoque_local.delete_recipe
  TO 'estoque_app'@'127.0.0.1';
