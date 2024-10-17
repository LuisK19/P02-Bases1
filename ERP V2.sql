-- Verificación de la existencia de la base de datos. Si no existe, se crea.
IF NOT EXISTS (SELECT [name] FROM sys.databases WHERE [name] = N'Sistema_ERP')
BEGIN
    CREATE DATABASE Sistema_ERP;  -- Crea la base de datos Sistema_ERP
END;

-- Selección de la base de datos que se usará para ejecutar las tablas y las consultas posteriores.
USE Sistema_ERP;
GO

-- CREACIÓN DE TABLAS DE CATÁLOGO (Tablas que definen categorías o roles dentro del sistema)

-- Tabla Departamento: Almacena información sobre los diferentes departamentos de la organización.
CREATE TABLE departamento (
    id_departamento INT PRIMARY KEY IDENTITY(1,1),  -- Identificador único para cada departamento
    nombre_departamento VARCHAR(50) NOT NULL,       -- Nombre del departamento (ej. Finanzas, TI)
    descripcion TEXT NOT NULL                       -- Descripción más detallada del departamento
);

-- Tabla Puesto: Define los diferentes puestos que pueden ocupar los empleados dentro de la empresa.
CREATE TABLE puesto (
    id_puesto INT PRIMARY KEY IDENTITY(1,1),        -- Identificador único para cada puesto
    nombre_puesto VARCHAR(50) NOT NULL,             -- Nombre del puesto (ej. Gerente, Analista)
    descripcion TEXT NOT NULL                       -- Descripción del puesto
);

-- Tabla Rol: Define los diferentes roles que pueden tener los empleados en el sistema (ej. Administrador, Usuario).
CREATE TABLE rol (
    id_rol INT PRIMARY KEY IDENTITY(1,1),           -- Identificador único para cada rol
    nombre_rol VARCHAR(50) NOT NULL,                -- Nombre del rol
    descripcion TEXT NOT NULL                       -- Descripción de los permisos o responsabilidades del rol
);

-- Tabla Zona: Define las zonas o áreas geográficas donde opera la empresa.
CREATE TABLE zona (
    id_zona INT PRIMARY KEY IDENTITY(1,1),          -- Identificador único para cada zona
    nombre_zona VARCHAR(50) NOT NULL,               -- Nombre de la zona
    descripcion TEXT NOT NULL                       -- Descripción de la zona
);

-- Tabla Sector: Representa los sectores dentro de las zonas donde la empresa tiene presencia.
CREATE TABLE sector (
    id_sector INT PRIMARY KEY IDENTITY(1,1),        -- Identificador único para cada sector
    nombre_sector VARCHAR(50) NOT NULL,             -- Nombre del sector
    descripcion TEXT NOT NULL                       -- Descripción del sector
);

-- CREACIÓN DE TABLAS RELACIONADAS CON PERMISOS Y SEGURIDAD

-- Tabla Permiso: Define los diferentes permisos que pueden asignarse a los roles del sistema.
CREATE TABLE permiso (
    id_permiso INT PRIMARY KEY IDENTITY(1,1),       -- Identificador único para cada permiso
    nombre_permiso VARCHAR(75) NOT NULL             -- Nombre del permiso (ej. Acceso a inventario, Generar facturas)
);

-- Tabla Rol_Permiso: Relaciona los roles con los permisos específicos. Indica qué permisos tiene cada rol.
CREATE TABLE rol_permiso (
    id_rol INT NOT NULL,                            -- Referencia al rol
    permiso_admin BIT NOT NULL DEFAULT 0,           -- Permiso de administración general
    permiso_inventario BIT NOT NULL DEFAULT 0,      -- Permiso para gestionar inventario
    permiso_cotizacion BIT NOT NULL DEFAULT 0,      -- Permiso para gestionar cotizaciones
    permiso_factura BIT NOT NULL DEFAULT 0,         -- Permiso para gestionar facturas
    CONSTRAINT FK_rol_permiso_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol), -- Llave foránea a la tabla rol
    PRIMARY KEY (id_rol)                            -- Llave primaria que asocia el rol con sus permisos
);

-- CREACIÓN DE TABLAS RELACIONADAS CON LOS EMPLEADOS

-- Tabla Empleado: Almacena la información de los empleados de la empresa.
CREATE TABLE empleado (
    cedula VARCHAR(12) PRIMARY KEY NOT NULL,        -- Identificador único del empleado (número de cédula)
    nombre VARCHAR(50) NOT NULL,                    -- Nombre del empleado
    primer_apellido VARCHAR(50) NOT NULL,           -- Primer apellido del empleado
    segundo_apellido VARCHAR(50) NOT NULL,          -- Segundo apellido del empleado
    fecha_nacimiento DATE NOT NULL,                 -- Fecha de nacimiento del empleado
    genero CHAR(1) NOT NULL CHECK(genero IN ('M', 'F')), -- Género del empleado ('M' para masculino, 'F' para femenino)
    lugar_residencia VARCHAR(150) NOT NULL,         -- Lugar de residencia del empleado
    telefono VARCHAR(8) NOT NULL UNIQUE,            -- Número de teléfono del empleado (único)
    salario_actual DECIMAL(10, 2) NOT NULL,         -- Salario actual del empleado
    id_puesto_actual INT NOT NULL,                  -- Referencia al puesto actual del empleado
    id_departamento_actual INT NOT NULL,            -- Referencia al departamento actual del empleado
    fecha_ingreso DATE NOT NULL,                    -- Fecha de ingreso del empleado a la empresa
    id_rol INT NOT NULL,                            -- Referencia al rol del empleado en el sistema
    edad AS DATEDIFF(YEAR, fecha_nacimiento, GETDATE()), -- Columna calculada: edad del empleado
    CONSTRAINT FK_rol_empleado FOREIGN KEY (id_rol) REFERENCES rol(id_rol), -- Llave foránea a la tabla rol
    CONSTRAINT FK_puesto_empleado FOREIGN KEY (id_puesto_actual) REFERENCES puesto(id_puesto), -- Llave foránea a la tabla puesto
    CONSTRAINT FK_departamento_empleado FOREIGN KEY (id_departamento_actual) REFERENCES departamento(id_departamento) -- Llave foránea a la tabla departamento
);

-- Tabla Login: Gestiona los datos de inicio de sesión de los empleados.
CREATE TABLE login (
    id_login INT PRIMARY KEY IDENTITY(1,1),         -- Identificador único para cada registro de inicio de sesión
    cedula VARCHAR(12) NOT NULL,                    -- Referencia a la cédula del empleado (relacionado con la tabla empleado)
    contrasena VARCHAR(60) NOT NULL,                -- Contraseña del empleado (almacenada de forma segura)
    id_rol INT NOT NULL,                            -- Referencia al rol del empleado (administrador, usuario, etc.)
    CONSTRAINT FK_login_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol), -- Llave foránea a la tabla rol
    CONSTRAINT FK_login_empleado FOREIGN KEY (cedula) REFERENCES empleado(cedula) -- Llave foránea a la tabla empleado
);

-- HISTORIAL DE PUESTOS Y SALARIOS (Control de cambios en puestos y salarios)

-- Tabla Historial Puesto: Almacena el historial de cambios de puesto para cada empleado.
CREATE TABLE historico_puesto (
    id_historial_puesto INT PRIMARY KEY IDENTITY(1,1), -- Identificador único para cada cambio de puesto
    cedula_empleado VARCHAR(12) NOT NULL,              -- Referencia al empleado que ha cambiado de puesto
    fecha_inicio DATE NOT NULL,                        -- Fecha en la que el empleado asumió el nuevo puesto
    fecha_fin DATE NOT NULL,                           -- Fecha en la que el empleado dejó el puesto
    nombre_puesto VARCHAR(60) NOT NULL,                -- Nombre del puesto
    departamento VARCHAR(60) NOT NULL,                 -- Departamento al que pertenece el puesto
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula) -- Llave foránea a la tabla empleado
);

-- Tabla Historial Salario: Almacena el historial de cambios salariales para los empleados.
CREATE TABLE historico_salario (
    id_historial_salario INT PRIMARY KEY IDENTITY(1,1), -- Identificador único para cada cambio salarial
    cedula_empleado VARCHAR(12) NOT NULL,               -- Referencia al empleado
    fecha_inicio DATE NOT NULL,                         -- Fecha en la que el nuevo salario comenzó a aplicarse
    fecha_fin DATE NOT NULL,                            -- Fecha en la que dejó de aplicarse ese salario
    nombre_puesto VARCHAR(60) NOT NULL,                 -- Puesto del empleado durante ese periodo
    departamento VARCHAR(60) NOT NULL,                  -- Departamento del empleado
    monto DECIMAL(10, 2) NOT NULL,                      -- Monto del salario durante ese periodo
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula) -- Llave foránea a la tabla empleado
);

-- CONTINÚA CON EL RESTO DE LAS TABLAS EXPLICADAS...


-- Tabla Planilla
CREATE TABLE planilla (
    mes TINYINT NOT NULL CHECK(mes BETWEEN 1 AND 12), -- Usamos el número del mes (1 = Enero, 12 = Diciembre)
    periodo INT NOT NULL, -- Periodo sinónimo de año
    monto_por_departamento DECIMAL(18, 2) NOT NULL, 
    monto_total_planilla_periodo DECIMAL(18, 2) NOT NULL,
    monto_total_planilla_mes DECIMAL(18, 2) NOT NULL,
    PRIMARY KEY (mes, periodo)
);

-- Tabla Registro Planilla
CREATE TABLE registro_planilla (
    cedula_empleado VARCHAR(12) NOT NULL,
    mes_planilla TINYINT NOT NULL CHECK(mes_planilla BETWEEN 1 AND 12), -- Usamos el número del mes
    periodo_planilla INT NOT NULL,
    horas_trabajadas INT NOT NULL,
    horas_extras INT,
    salario_calculado DECIMAL(18, 2) NOT NULL,
    PRIMARY KEY (cedula_empleado, mes_planilla, periodo_planilla),
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula),
    FOREIGN KEY (mes_planilla, periodo_planilla) REFERENCES planilla(mes, periodo)
);


-- Tabla Familia Artículo
CREATE TABLE familia_articulo (
    codigo_familia VARCHAR(20) PRIMARY KEY, 
    nombre_familia VARCHAR(100) NOT NULL,   
    activo BIT NOT NULL,
    descripcion TEXT NOT NULL
);

-- Tabla Artículo
CREATE TABLE articulo (
    codigo_articulo VARCHAR(20) PRIMARY KEY, 
    nombre_articulo VARCHAR(100) NOT NULL,   
    activo BIT NOT NULL,                     
    descripcion TEXT NOT NULL,              
    peso DECIMAL(10, 2) NOT NULL,             
    costo DECIMAL(18, 2) NOT NULL,           
    precio_estandar DECIMAL(18, 2) NOT NULL, 
    codigo_familia VARCHAR(20) NOT NULL,
    FOREIGN KEY (codigo_familia) REFERENCES familia_articulo(codigo_familia)
);

-- Tabla Inventario
CREATE TABLE inventario (
    id_inventario INT PRIMARY KEY IDENTITY(1,1),
    id_bodega INT NOT NULL,
    codigo_articulo VARCHAR(20) NOT NULL,
    cantidad INT NOT NULL,
    FOREIGN KEY (id_bodega) REFERENCES bodega(id_bodega),
    FOREIGN KEY (codigo_articulo) REFERENCES articulo(codigo_articulo)
);

-- Tabla Bodega
CREATE TABLE bodega (
    id_bodega INT PRIMARY KEY IDENTITY(1,1),
    nombre_bodega VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(255) NOT NULL,
    capacidad_toneladas DECIMAL(10, 2) NOT NULL,
    espacio_cubico DECIMAL(10, 2) NOT NULL
);

-- Tabla Bodega Familia
CREATE TABLE bodega_familia (
    id_bodega INT NOT NULL,
    codigo_familia VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_bodega, codigo_familia),
    FOREIGN KEY (id_bodega) REFERENCES bodega(id_bodega),
    FOREIGN KEY (codigo_familia) REFERENCES familia_articulo(codigo_familia)
);

-- Tabla Movimiento Inventario
CREATE TABLE movimiento_inventario (
    id_movimiento INT PRIMARY KEY IDENTITY(1,1),
    fecha_hora DATETIME NOT NULL,
    tipo_movimiento VARCHAR(50) NOT NULL CHECK(tipo_movimiento IN ('Entrada','Salida','Entre bodegas')),
    cedula_empleado VARCHAR(12) NOT NULL,
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula)
);

-- Tabla Movimiento Entrada
CREATE TABLE movimiento_entrada (
    id_movimiento INT NOT NULL,
    cedula_empleado VARCHAR(12) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    bodega_destino INT NOT NULL,
    codigo_articulo VARCHAR(20) NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_movimiento, cedula_empleado),
    FOREIGN KEY (id_movimiento) REFERENCES movimiento_inventario(id_movimiento),
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula),
    FOREIGN KEY (bodega_destino) REFERENCES bodega(id_bodega),
    FOREIGN KEY (codigo_articulo) REFERENCES articulo(codigo_articulo)
);

-- Tabla Movimiento Entre Bodegas
CREATE TABLE movimiento_entre_bodegas (
    id_movimiento INT NOT NULL,
    cedula_empleado VARCHAR(12) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    bodega_origen INT NOT NULL,
    bodega_destino INT NOT NULL,
    codigo_articulo VARCHAR(20) NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_movimiento, cedula_empleado),
    FOREIGN KEY (id_movimiento) REFERENCES movimiento_inventario(id_movimiento),
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula),
    FOREIGN KEY (bodega_origen) REFERENCES bodega(id_bodega),
    FOREIGN KEY (bodega_destino) REFERENCES bodega(id_bodega),
    FOREIGN KEY (codigo_articulo) REFERENCES articulo(codigo_articulo)
);

-- Tabla Movimiento Salida
CREATE TABLE movimiento_salida (
    id_movimiento INT NOT NULL,
    cedula_empleado VARCHAR(12) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    bodega_origen INT NOT NULL,
    codigo_articulo VARCHAR(20) NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_movimiento, cedula_empleado),
    FOREIGN KEY (id_movimiento) REFERENCES movimiento_inventario(id_movimiento),
    FOREIGN KEY (cedula_empleado) REFERENCES empleado(cedula),
    FOREIGN KEY (bodega_origen) REFERENCES bodega(id_bodega),
    FOREIGN KEY (codigo_articulo) REFERENCES articulo(codigo_articulo)
);
