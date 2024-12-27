CREATE TABLE `db_version` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `version` integer UNIQUE NOT NULL,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

CREATE TABLE `users` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `userName` varchar(32) UNIQUE NOT NULL,
  `email` varchar(128) UNIQUE NOT NULL,
  `firstName` varchar(32) NOT NULL,
  `personalBudget` integer NOT NULL,
  `isActive` boolean DEFAULT false,
  `passwordResetRequest` boolean DEFAULT false,
  `lastPasswordReset` date DEFAULT null,
  `isAdmin` boolean DEFAULT false,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

CREATE TABLE `outgoings` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `ownerID` integer NOT NULL,
  `name` varchar(64) NOT NULL,
  `description` varchar(512),
  `amount` integer NOT NULL,
  `priority` integer DEFAULT 1,
  `categoryID` integer NOT NULL,
  `commentID` integer NOT NULL,
  `isActive` boolean DEFAULT true,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

CREATE TABLE `categories` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(64) UNIQUE NOT NULL,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

CREATE TABLE `tags` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(32) UNIQUE NOT NULL,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

CREATE TABLE `outgoings_tags` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `tagID` integer NOT NULL,
  `outgoingID` integer NOT NULL,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

CREATE TABLE `outgoings_comments` (
  `id` integer PRIMARY KEY AUTO_INCREMENT,
  `ownerID` integer NOT NULL,
  `outgoingID` integer NOT NULL,
  `comment` varchar(512) NOT NULL,
  `createdAt` timestamp DEFAULT NOW(),
  `updatedAt` timestamp DEFAULT NOW() on update NOW()
);

ALTER TABLE `outgoings` ADD FOREIGN KEY (`ownerID`) REFERENCES `users` (`id`);
ALTER TABLE `outgoings` ADD FOREIGN KEY (`categoryID`) REFERENCES `categories` (`id`);
ALTER TABLE `outgoings` ADD FOREIGN KEY (`commentID`) REFERENCES `outgoings_comments` (`id`);

ALTER TABLE `outgoings_tags` ADD FOREIGN KEY (`tagID`) REFERENCES `tags` (`id`);
ALTER TABLE `outgoings_tags` ADD FOREIGN KEY (`outgoingID`) REFERENCES `outgoings` (`id`);

ALTER TABLE `outgoings_comments` ADD FOREIGN KEY (`ownerID`) REFERENCES `users` (`id`);
ALTER TABLE `outgoings_comments` ADD FOREIGN KEY (`outgoingID`) REFERENCES `outgoings` (`id`);