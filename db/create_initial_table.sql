CREATE TABLE `recruits` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `user` text,
    `repos` text,
    `issues` text,
    `pullrequests` text,
    `gists` text,
    `comments` text,
    `created_at` datetime NOT NULL,
    `updated_at` datetime NOT NULL,
    `deleted_at` datetime DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
