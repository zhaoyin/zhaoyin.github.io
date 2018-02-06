
---
title: mysql修改表、字段、库的字符集
date: 2017-10-25 09:20:46
categories:
    - tuning
tags: 
    - mysql
---

## 修改数据库字符集

```angularjs
ALTER DATABASE db_name DEFAULT CHARACTER SET character_name [COLLATE ...];

ALTER DATABASE db_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 把表默认的字符集和所有字符列（CHAR,VARCHAR,TEXT）改为新的字符集

```
ALTER TABLE tbl_name CONVERT TO CHARACTER SET character_name [COLLATE ...]
如：ALTER TABLE logtest CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

## 只是修改表的默认字符集

```
ALTER TABLE tbl_name DEFAULT CHARACTER SET character_name [COLLATE...];
如：ALTER TABLE logtest DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

## 修改字段的字符集

```
ALTER TABLE tbl_name CHANGE c_name c_name CHARACTER SET character_name [COLLATE ...];
如：ALTER TABLE logtest CHANGE title title VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

## 查看数据库编码

```
SHOW CREATE DATABASE db_name;
```

## 查看表编码

```
SHOW CREATE TABLE tbl_name;
```

## 查看字段编码

```
SHOW FULL COLUMNS FROM tbl_name;
```

## 关于utf8mb4

MySQLUTF8 编码只支持 1-3 个字节。而 emoji 占有 4 个字节的存储空间，所以自然保存不了。
从 MYSQL5.5 开始，可支持 4 个字节 UTF 编码，只要将编码标记成 utf8mb4 即可。并且 utf8mb4 是兼容 utf8 的。
