-- MariaDB 10.4 initial schema for a new, local clone database.
-- Run once against an empty database. This is a schema bootstrap, not a migration
-- of live Supabase data. DDL is idempotent where MariaDB supports IF NOT EXISTS;
-- triggers/procedures are intentionally created once and need explicit DROP to rerun.
--
-- Trust boundary: MariaDB has no Supabase Auth/RLS equivalent. The application
-- server must authenticate users, authorize every request, and connect with a
-- restricted DB account. Do not expose DB credentials to the browser. Restrict
-- direct UPDATE of products.quantity and direct INSERT into movements; all stock
-- changes must be inserts through append_movement(). The trigger below is the
-- sole saldo applier. Stored procedure actor IDs are not authentication proofs.

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_users (
  id CHAR(36) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY app_users_email_uq (email),
  CONSTRAINT app_users_active_ck CHECK (active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_spaces (
  id CHAR(36) NOT NULL,
  name VARCHAR(120) NOT NULL,
  created_by CHAR(36) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  CONSTRAINT inventory_spaces_creator_fk FOREIGN KEY (created_by)
    REFERENCES app_users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_members (
  user_id CHAR(36) NOT NULL,
  inventory_id CHAR(36) NOT NULL,
  role ENUM('admin', 'operator', 'viewer') NOT NULL DEFAULT 'viewer',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (user_id),
  KEY inventory_members_inventory_idx (inventory_id, user_id),
  CONSTRAINT inventory_members_user_fk FOREIGN KEY (user_id)
    REFERENCES app_users(id) ON DELETE CASCADE,
  CONSTRAINT inventory_members_inventory_fk FOREIGN KEY (inventory_id)
    REFERENCES inventory_spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Store only a cryptographic hash of a random opaque session token. The API
-- must generate/rotate tokens, set a Secure/HttpOnly/SameSite cookie, hash the
-- presented token, and enforce expires_at and app_users.active on each request.
CREATE TABLE IF NOT EXISTS user_sessions (
  token_hash BINARY(32) NOT NULL,
  user_id CHAR(36) NOT NULL,
  expires_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (token_hash),
  KEY user_sessions_user_expiry_idx (user_id, expires_at),
  CONSTRAINT user_sessions_user_fk FOREIGN KEY (user_id)
    REFERENCES app_users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS product_code_counter (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  id CHAR(36) NOT NULL,
  inventory_id CHAR(36) NOT NULL,
  created_by CHAR(36) NOT NULL,
  created_by_email VARCHAR(254) NOT NULL DEFAULT '',
  name VARCHAR(255) NOT NULL,
  unit ENUM('UN', 'GR', 'ML') NOT NULL DEFAULT 'UN',
  quantity DECIMAL(14,3) NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  active TINYINT(1) NOT NULL DEFAULT 1,
  code CHAR(10) NOT NULL,
  notes TEXT NOT NULL,
  cancelled TINYINT(1) NOT NULL DEFAULT 0,
  pending_registration TINYINT(1) NOT NULL DEFAULT 0,
  grams_per_unit INT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY products_code_uq (code),
  KEY products_name_unit_idx (name, unit),
  KEY products_inventory_created_idx (inventory_id, created_at),
  CONSTRAINT products_inventory_fk FOREIGN KEY (inventory_id)
    REFERENCES inventory_spaces(id) ON DELETE CASCADE,
  CONSTRAINT products_creator_fk FOREIGN KEY (created_by)
    REFERENCES app_users(id) ON DELETE RESTRICT,
  CONSTRAINT products_quantity_ck CHECK (quantity >= 0),
  CONSTRAINT products_active_ck CHECK (active IN (0, 1)),
  CONSTRAINT products_cancelled_ck CHECK (cancelled IN (0, 1)),
  CONSTRAINT products_pending_ck CHECK (pending_registration IN (0, 1)),
  CONSTRAINT products_code_ck CHECK (code REGEXP '^MP[0-9]{8}$'),
  CONSTRAINT products_grams_per_unit_ck CHECK (
    grams_per_unit IS NULL OR (unit = 'GR' AND grams_per_unit > 0)
  )
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movements (
  id CHAR(36) NOT NULL,
  created_by CHAR(36) NOT NULL,
  created_by_email VARCHAR(254) NOT NULL DEFAULT '',
  product_id CHAR(36) NOT NULL,
  type ENUM('entrada', 'saida') NOT NULL,
  quantity DECIMAL(14,3) NOT NULL,
  unit_price DECIMAL(14,6) NOT NULL DEFAULT 0,
  note TEXT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY movements_product_created_idx (product_id, created_at),
  KEY movements_created_idx (created_at),
  CONSTRAINT movements_creator_fk FOREIGN KEY (created_by)
    REFERENCES app_users(id) ON DELETE RESTRICT,
  CONSTRAINT movements_product_fk FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE RESTRICT,
  CONSTRAINT movements_quantity_ck CHECK (quantity > 0),
  CONSTRAINT movements_price_ck CHECK (unit_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipes (
  id CHAR(36) NOT NULL,
  inventory_id CHAR(36) NOT NULL,
  name VARCHAR(120) NOT NULL,
  portions INT NOT NULL,
  created_by CHAR(36) NOT NULL,
  created_by_email VARCHAR(254) NOT NULL DEFAULT '',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY recipes_created_idx (created_at),
  KEY recipes_inventory_created_idx (inventory_id, created_at),
  CONSTRAINT recipes_inventory_fk FOREIGN KEY (inventory_id)
    REFERENCES inventory_spaces(id) ON DELETE CASCADE,
  CONSTRAINT recipes_creator_fk FOREIGN KEY (created_by)
    REFERENCES app_users(id) ON DELETE RESTRICT,
  CONSTRAINT recipes_name_ck CHECK (CHAR_LENGTH(TRIM(name)) BETWEEN 1 AND 120),
  CONSTRAINT recipes_portions_ck CHECK (portions > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id CHAR(36) NOT NULL,
  recipe_id CHAR(36) NOT NULL,
  product_id CHAR(36) NULL,
  name VARCHAR(120) NOT NULL,
  quantity INT NOT NULL,
  unit ENUM('UN', 'GR', 'ML') NOT NULL,
  position INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY recipe_ingredients_order_idx (recipe_id, position),
  KEY recipe_ingredients_product_unit_idx (product_id, unit),
  CONSTRAINT recipe_ingredients_recipe_fk FOREIGN KEY (recipe_id)
    REFERENCES recipes(id) ON DELETE CASCADE,
  CONSTRAINT recipe_ingredients_product_fk FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE SET NULL,
  CONSTRAINT recipe_ingredients_name_ck CHECK (CHAR_LENGTH(TRIM(name)) BETWEEN 1 AND 120),
  CONSTRAINT recipe_ingredients_quantity_ck CHECK (quantity > 0),
  CONSTRAINT recipe_ingredients_position_ck CHECK (position >= 0)
) ENGINE=InnoDB;

DELIMITER //

CREATE TRIGGER products_before_insert
BEFORE INSERT ON products FOR EACH ROW
BEGIN
  DECLARE next_code BIGINT UNSIGNED;
  DECLARE creator_email_value VARCHAR(254);
  DECLARE creator_inventory_value CHAR(36);
  IF NEW.id IS NULL OR NEW.id = '' THEN
    SET NEW.id = UUID();
  END IF;
  IF NEW.created_by IS NULL OR NEW.created_by = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'created_by is required';
  END IF;
  SELECT email INTO creator_email_value FROM app_users WHERE id = NEW.created_by;
  SELECT inventory_id INTO creator_inventory_value FROM inventory_members WHERE user_id=NEW.created_by;
  IF creator_email_value IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'creator user not found';
  END IF;
  IF creator_inventory_value IS NULL OR creator_inventory_value <> NEW.inventory_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product must belong to creator inventory';
  END IF;
  SET NEW.created_by_email = creator_email_value;
  IF NEW.code IS NULL OR NEW.code = '' THEN
    INSERT INTO product_code_counter VALUES (NULL);
    SET next_code = LAST_INSERT_ID();
    IF next_code > 99999999 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product code sequence exhausted';
    END IF;
    SET NEW.code = CONCAT('MP', LPAD(next_code, 8, '0'));
  END IF;
  IF NEW.notes IS NULL THEN SET NEW.notes = ''; END IF;
  IF NEW.unit IN ('UN', 'GR', 'ML') AND NEW.quantity <> TRUNCATE(NEW.quantity, 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UN, GR and ML quantities must be integers';
  END IF;
END//

CREATE TRIGGER products_before_update
BEFORE UPDATE ON products FOR EACH ROW
BEGIN
  IF NEW.quantity <> OLD.quantity AND COALESCE(@inventory_movement_applying, 0) <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantity can only change through a movement insert';
  END IF;
  IF OLD.grams_per_unit IS NOT NULL AND NEW.grams_per_unit IS NULL
    AND EXISTS (SELECT 1 FROM recipe_ingredients WHERE product_id = OLD.id AND unit = 'UN') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'conversion is used by a recipe';
  END IF;
END//

CREATE TRIGGER movements_before_insert
BEFORE INSERT ON movements FOR EACH ROW
BEGIN
  DECLARE product_unit VARCHAR(2);
  DECLARE product_quantity DECIMAL(14,3);
  DECLARE product_is_active TINYINT;
  DECLARE product_is_cancelled TINYINT;
  DECLARE product_is_pending TINYINT;
  DECLARE creator_email_value VARCHAR(254);
  SELECT email INTO creator_email_value FROM app_users WHERE id = NEW.created_by AND active = 1;
  IF creator_email_value IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'active creator user required';
  END IF;
  SET NEW.created_by_email = creator_email_value;
  SELECT unit, quantity, active, cancelled, pending_registration
    INTO product_unit, product_quantity, product_is_active, product_is_cancelled, product_is_pending
    FROM products WHERE id = NEW.product_id FOR UPDATE;
  IF product_unit IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product not found'; END IF;
  IF product_is_cancelled = 1 OR product_is_pending = 1 OR product_is_active = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product cannot be moved in its current state';
  END IF;
  IF NEW.quantity <= 0 OR NEW.quantity <> TRUNCATE(NEW.quantity, 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'movement quantity must be a positive integer';
  END IF;
  IF NEW.type = 'saida' THEN
    SET NEW.unit_price = 0;
    IF product_quantity < NEW.quantity THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'insufficient stock'; END IF;
    SET @inventory_movement_applying = 1;
    UPDATE products SET quantity = quantity - NEW.quantity WHERE id = NEW.product_id;
    SET @inventory_movement_applying = NULL;
  ELSE
    SET @inventory_movement_applying = 1;
    UPDATE products SET quantity = quantity + NEW.quantity WHERE id = NEW.product_id;
    SET @inventory_movement_applying = NULL;
  END IF;
END//

CREATE TRIGGER recipes_before_insert
BEFORE INSERT ON recipes FOR EACH ROW
BEGIN
  DECLARE creator_email_value VARCHAR(254);
  DECLARE creator_inventory_value CHAR(36);
  SELECT email INTO creator_email_value FROM app_users WHERE id = NEW.created_by AND active = 1;
  SELECT inventory_id INTO creator_inventory_value FROM inventory_members WHERE user_id=NEW.created_by;
  IF creator_email_value IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'active creator user required'; END IF;
  IF creator_inventory_value IS NULL OR creator_inventory_value <> NEW.inventory_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'recipe must belong to creator inventory';
  END IF;
  SET NEW.created_by_email = creator_email_value;
  SET NEW.name = TRIM(NEW.name);
END//

CREATE TRIGGER recipe_ingredients_before_insert
BEFORE INSERT ON recipe_ingredients FOR EACH ROW
BEGIN
  DECLARE product_name_value VARCHAR(255);
  DECLARE product_unit_value VARCHAR(2);
  DECLARE product_active_value TINYINT;
  DECLARE product_cancelled_value TINYINT;
  DECLARE product_grams_value INT UNSIGNED;
  DECLARE recipe_inventory_value CHAR(36);
  DECLARE product_inventory_value CHAR(36);
  IF NEW.product_id IS NOT NULL THEN
    SELECT name, unit, active, cancelled, grams_per_unit, inventory_id
      INTO product_name_value, product_unit_value, product_active_value, product_cancelled_value, product_grams_value, product_inventory_value
      FROM products WHERE id = NEW.product_id;
    SELECT inventory_id INTO recipe_inventory_value FROM recipes WHERE id=NEW.recipe_id;
    IF recipe_inventory_value IS NULL OR product_inventory_value <> recipe_inventory_value THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ingredient product belongs to another inventory';
    END IF;
    IF product_name_value IS NULL OR product_active_value = 0 OR product_cancelled_value = 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ingredient product is unavailable';
    END IF;
    IF product_name_value <> NEW.name THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ingredient name must match product'; END IF;
    IF product_unit_value <> NEW.unit AND NOT (product_unit_value = 'GR' AND NEW.unit = 'UN' AND product_grams_value IS NOT NULL) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ingredient unit does not match product';
    END IF;
  END IF;
END//

CREATE PROCEDURE append_movement(
  IN p_movement_id CHAR(36), IN p_actor_id CHAR(36), IN p_product_id CHAR(36), IN p_type VARCHAR(10),
  IN p_quantity DECIMAL(14,3), IN p_unit_price DECIMAL(14,6), IN p_note TEXT
)
SQL SECURITY DEFINER
BEGIN
  DECLARE actor_role VARCHAR(10);
  DECLARE actor_inventory_id CHAR(36);
  DECLARE movement_id CHAR(36);
  SELECT role, inventory_id INTO actor_role, actor_inventory_id FROM inventory_members m JOIN app_users u ON u.id=m.user_id
    WHERE m.user_id=p_actor_id AND u.active=1;
  IF actor_role IS NULL OR actor_role NOT IN ('admin','operator') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'operator role required';
  END IF;
  IF p_type NOT IN ('entrada','saida') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid movement type'; END IF;
  IF NOT EXISTS(SELECT 1 FROM products WHERE id=p_product_id AND inventory_id=actor_inventory_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product not found in this inventory';
  END IF;
  SET movement_id=COALESCE(NULLIF(p_movement_id,''), UUID());
  INSERT INTO movements(id, created_by, product_id, type, quantity, unit_price, note)
    VALUES(movement_id, p_actor_id, p_product_id, p_type, p_quantity, COALESCE(p_unit_price,0), p_note);
  SELECT movement_id AS movement_id;
END//

CREATE PROCEDURE set_inventory_role(IN p_actor_id CHAR(36), IN p_user_id CHAR(36), IN p_role VARCHAR(10))
SQL SECURITY DEFINER
BEGIN
  DECLARE actor_role VARCHAR(10);
  DECLARE member_role VARCHAR(10);
  DECLARE admin_count INT;
  DECLARE lock_result INT;
  DECLARE actor_inventory_id CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DO RELEASE_LOCK('inventory_role_changes');
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT GET_LOCK('inventory_role_changes', 10) INTO lock_result;
  IF lock_result <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'could not lock role changes'; END IF;
  SELECT role, inventory_id INTO actor_role, actor_inventory_id FROM inventory_members WHERE user_id=p_actor_id FOR UPDATE;
  IF COALESCE(actor_role,'') <> 'admin' OR p_role NOT IN ('admin','operator','viewer') THEN
    DO RELEASE_LOCK('inventory_role_changes');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'admin role required or invalid role';
  END IF;
  SELECT role INTO member_role FROM inventory_members WHERE user_id=p_user_id AND inventory_id=actor_inventory_id FOR UPDATE;
  IF member_role IS NULL THEN DO RELEASE_LOCK('inventory_role_changes'); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'member not found'; END IF;
  IF member_role='admin' AND p_role<>'admin' THEN
    SELECT COUNT(*) INTO admin_count FROM inventory_members WHERE role='admin' AND inventory_id=actor_inventory_id;
    IF admin_count<=1 THEN DO RELEASE_LOCK('inventory_role_changes'); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'at least one admin must remain'; END IF;
  END IF;
  UPDATE inventory_members SET role=p_role WHERE user_id=p_user_id AND inventory_id=actor_inventory_id;
  COMMIT;
  DO RELEASE_LOCK('inventory_role_changes');
END//

CREATE PROCEDURE set_product_active(IN p_actor_id CHAR(36), IN p_product_id CHAR(36), IN p_active TINYINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE actor_role VARCHAR(10);
  DECLARE stock DECIMAL(14,3);
  DECLARE is_cancelled TINYINT;
  DECLARE is_pending TINYINT;
  DECLARE actor_inventory_id CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT m.role,m.inventory_id INTO actor_role,actor_inventory_id FROM inventory_members m JOIN app_users u ON u.id=m.user_id
    WHERE m.user_id=p_actor_id AND u.active=1;
  IF COALESCE(actor_role,'') NOT IN ('admin','operator') OR p_active NOT IN (0,1) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'operator role required or invalid state'; END IF;
  SELECT quantity,cancelled,pending_registration INTO stock,is_cancelled,is_pending FROM products WHERE id=p_product_id AND inventory_id=actor_inventory_id FOR UPDATE;
  IF stock IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product not found'; END IF;
  IF is_cancelled=1 OR is_pending=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'restore cancelled product or finalize preregistration first'; END IF;
  IF p_active=0 AND stock<>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock must be zero before deactivation'; END IF;
  UPDATE products SET active=p_active WHERE id=p_product_id AND inventory_id=actor_inventory_id;
  COMMIT;
END//

CREATE PROCEDURE set_product_cancelled(IN p_actor_id CHAR(36), IN p_product_id CHAR(36), IN p_cancelled TINYINT)
SQL SECURITY DEFINER
BEGIN
  DECLARE actor_role VARCHAR(10);
  DECLARE actor_inventory_id CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT m.role,m.inventory_id INTO actor_role,actor_inventory_id FROM inventory_members m JOIN app_users u ON u.id=m.user_id
    WHERE m.user_id=p_actor_id AND u.active=1;
  IF COALESCE(actor_role,'') NOT IN ('admin','operator') OR p_cancelled NOT IN (0,1) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'operator role required or invalid state'; END IF;
  UPDATE products SET cancelled=p_cancelled WHERE id=p_product_id AND inventory_id=actor_inventory_id;
  IF ROW_COUNT()=0 AND NOT EXISTS(SELECT 1 FROM products WHERE id=p_product_id AND inventory_id=actor_inventory_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product not found'; END IF;
  COMMIT;
END//

CREATE PROCEDURE finalize_inventory_product(IN p_actor_id CHAR(36), IN p_product_id CHAR(36))
SQL SECURITY DEFINER
BEGIN
  DECLARE actor_role VARCHAR(10);
  DECLARE product_pending TINYINT;
  DECLARE actor_inventory_id CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT m.role,m.inventory_id INTO actor_role,actor_inventory_id FROM inventory_members m JOIN app_users u ON u.id=m.user_id
    WHERE m.user_id=p_actor_id AND u.active=1;
  IF COALESCE(actor_role,'') NOT IN ('admin','operator') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'operator role required'; END IF;
  SELECT pending_registration INTO product_pending FROM products WHERE id=p_product_id AND inventory_id=actor_inventory_id FOR UPDATE;
  IF product_pending IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product not found'; END IF;
  IF product_pending=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'product is already finalized'; END IF;
  UPDATE products SET pending_registration=0 WHERE id=p_product_id AND inventory_id=actor_inventory_id;
  COMMIT;
END//

CREATE PROCEDURE save_recipe(
  IN p_actor_id CHAR(36), IN p_recipe_id CHAR(36), IN p_name VARCHAR(120),
  IN p_portions INT, IN p_ingredients JSON
)
SQL SECURITY DEFINER
BEGIN
  DECLARE saved_id CHAR(36);
  DECLARE ingredient_count INT;
  DECLARE i INT DEFAULT 0;
  DECLARE ingredient_name VARCHAR(120);
  DECLARE ingredient_unit VARCHAR(2);
  DECLARE ingredient_quantity INT;
  DECLARE ingredient_product_id CHAR(36);
  DECLARE actor_role VARCHAR(10);
  DECLARE actor_inventory_id CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT m.role,m.inventory_id INTO actor_role,actor_inventory_id FROM inventory_members m JOIN app_users u ON u.id=m.user_id
    WHERE m.user_id=p_actor_id AND u.active=1;
  IF actor_role IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'authentication required'; END IF;
  IF p_name IS NULL OR CHAR_LENGTH(TRIM(p_name)) NOT BETWEEN 1 AND 120 OR p_portions IS NULL OR p_portions<=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid recipe name or portions'; END IF;
  IF p_ingredients IS NULL OR JSON_TYPE(p_ingredients)<>'ARRAY' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ingredients must be a JSON array'; END IF;
  SET ingredient_count=JSON_LENGTH(p_ingredients);
  IF ingredient_count=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'at least one ingredient required'; END IF;
  IF p_recipe_id IS NULL OR p_recipe_id='' THEN
    SET saved_id=UUID();
    INSERT INTO recipes(id,inventory_id,name,portions,created_by) VALUES(saved_id,actor_inventory_id,TRIM(p_name),p_portions,p_actor_id);
  ELSE
    UPDATE recipes SET name=TRIM(p_name),portions=p_portions,updated_at=CURRENT_TIMESTAMP(3)
      WHERE id=p_recipe_id AND created_by=p_actor_id AND inventory_id=actor_inventory_id;
    IF ROW_COUNT()=0 AND NOT EXISTS(SELECT 1 FROM recipes WHERE id=p_recipe_id AND created_by=p_actor_id AND inventory_id=actor_inventory_id) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'recipe not found or not owned by actor';
    END IF;
    SET saved_id=p_recipe_id;
    DELETE FROM recipe_ingredients WHERE recipe_id=saved_id;
  END IF;
  WHILE i<ingredient_count DO
    SET ingredient_name=TRIM(JSON_UNQUOTE(JSON_EXTRACT(p_ingredients,CONCAT('$[',i,'].name'))));
    SET ingredient_unit=JSON_UNQUOTE(JSON_EXTRACT(p_ingredients,CONCAT('$[',i,'].unit')));
    SET ingredient_quantity=CAST(JSON_UNQUOTE(JSON_EXTRACT(p_ingredients,CONCAT('$[',i,'].quantity'))) AS SIGNED);
    SET ingredient_product_id=NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_ingredients,CONCAT('$[',i,'].product_id'))),'null');
    IF ingredient_name IS NULL OR CHAR_LENGTH(ingredient_name) NOT BETWEEN 1 AND 120 OR ingredient_quantity IS NULL OR ingredient_quantity<=0 OR ingredient_unit NOT IN ('UN','GR','ML') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid recipe ingredient';
    END IF;
    IF ingredient_product_id IS NULL THEN
      SELECT id INTO ingredient_product_id FROM products
       WHERE inventory_id=actor_inventory_id AND LOWER(TRIM(name))=LOWER(ingredient_name) AND unit=ingredient_unit AND active=1 AND cancelled=0 AND pending_registration=0
       ORDER BY created_at,id LIMIT 1;
      IF ingredient_product_id IS NULL AND actor_role IN ('admin','operator')
        AND NOT EXISTS(SELECT 1 FROM products WHERE inventory_id=actor_inventory_id AND LOWER(TRIM(name))=LOWER(ingredient_name)) THEN
        SET ingredient_product_id=UUID();
        INSERT INTO products(id,inventory_id,created_by,name,unit,code,notes,pending_registration)
          VALUES(ingredient_product_id,actor_inventory_id,p_actor_id,ingredient_name,ingredient_unit,'', '',1);
      END IF;
    END IF;
    INSERT INTO recipe_ingredients(id,recipe_id,product_id,name,quantity,unit,position)
      VALUES(UUID(),saved_id,ingredient_product_id,ingredient_name,ingredient_quantity,ingredient_unit,i);
    SET i=i+1;
  END WHILE;
  COMMIT;
  SELECT saved_id AS recipe_id;
END//

CREATE PROCEDURE register_user(
  IN p_id CHAR(36), IN p_email VARCHAR(254), IN p_password_hash VARCHAR(255)
)
SQL SECURITY DEFINER
BEGIN
  DECLARE inventory_id_value CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  IF p_id IS NULL OR p_id='' OR p_email IS NULL OR CHAR_LENGTH(TRIM(p_email))=0
    OR p_password_hash IS NULL OR CHAR_LENGTH(p_password_hash)=0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'user id, email and password hash are required';
  END IF;
  INSERT INTO app_users(id,email,password_hash,active)
    VALUES(p_id,TRIM(p_email),p_password_hash,1);
  SET inventory_id_value=UUID();
  INSERT INTO inventory_spaces(id,name,created_by)
    VALUES(inventory_id_value, CONCAT('Estoque de ', SUBSTRING_INDEX(TRIM(p_email),'@',1)), p_id);
  INSERT INTO inventory_members(user_id,inventory_id,role) VALUES(p_id,inventory_id_value,'admin');
  COMMIT;
END//

CREATE PROCEDURE delete_recipe(IN p_actor_id CHAR(36), IN p_recipe_id CHAR(36))
SQL SECURITY DEFINER
BEGIN
  DECLARE affected_rows INT;
  DECLARE actor_inventory_id CHAR(36);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  IF NOT EXISTS (SELECT 1 FROM app_users WHERE id=p_actor_id AND active=1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'authentication required';
  END IF;
  SELECT inventory_id INTO actor_inventory_id FROM inventory_members WHERE user_id=p_actor_id;
  DELETE FROM recipes WHERE id=p_recipe_id AND inventory_id=actor_inventory_id AND created_by=p_actor_id;
  SET affected_rows=ROW_COUNT();
  IF affected_rows=0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'recipe not found or not owned by actor';
  END IF;
  COMMIT;
END//

DELIMITER ;

-- Authorization grants are a deployment responsibility. Each new account starts as admin of its own private inventory.
-- Create a separate least-privilege MariaDB account for the server, grant only
-- required table reads and EXECUTE on approved routines, and deny direct writes
-- to products.quantity and movements. Do not hard-code an email/password here.
-- MariaDB CHECK enforcement and JSON routine behavior must be verified against
-- the exact XAMPP MariaDB build before relying on them operationally.
