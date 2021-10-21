CREATE TABLE IF NOT EXISTS `renzu_nitro` (
  `plate` varchar(64) NOT NULL DEFAULT '',
  `nitro` longtext NULL,
  `value` int(3) NOT NULL DEFAULT 100,
  `bottle` varchar(32) NOT NULL DEFAULT 'nitro_bottle',
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;