-- phpMyAdmin SQL Dump
-- version 5.2.1deb1+deb12u1
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : mar. 09 déc. 2025 à 18:48
-- Version du serveur : 10.11.14-MariaDB-0+deb12u2
-- Version de PHP : 8.2.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `s1_lafolie`
--

-- --------------------------------------------------------

--
-- Structure de la table `gunfight_stats`
--

CREATE TABLE `gunfight_stats` (
  `id` int(11) NOT NULL,
  `identifier` varchar(60) NOT NULL,
  `player_name` varchar(100) DEFAULT 'Joueur Inconnu',
  `kills` int(11) NOT NULL DEFAULT 0,
  `deaths` int(11) NOT NULL DEFAULT 0,
  `headshots` int(11) NOT NULL DEFAULT 0,
  `best_streak` int(11) NOT NULL DEFAULT 0,
  `total_playtime` int(11) NOT NULL DEFAULT 0 COMMENT 'Temps de jeu en secondes',
  `last_played` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `gunfight_stats`
--

INSERT INTO `gunfight_stats` (`id`, `identifier`, `player_name`, `kills`, `deaths`, `headshots`, `best_streak`, `total_playtime`, `last_played`) VALUES
(6, 'e2cd407c2adbd534146445506365a4a26a288fb0', 'kichta boy', 45, 138, 0, 5, 8553, '2025-12-09 13:14:08'),
(28, '3d97650200dea8a6d258e2b2d6f223a2aa5f69ba', 'EN  BRRRRRR', 10118, 117, 0, 5000, 7370, '2025-12-09 10:42:46'),
(36, 'e5e96bb82d838846e71eb1966ddbef606cc4248f', 'Joueur Inconnu', 0, 0, 0, 0, 0, '2025-12-04 12:00:01'),
(37, '80a2da7b25612e10f790e916ca75dccce024d223', 'Joueur Inconnu', 0, 0, 0, 1, 0, '2025-12-06 20:21:52'),
(38, '9a436f4662344dc09cdb0350aa8493462b77ae86', 'Dogan Doskow', 12, 8, 0, 6, 159, '2025-12-07 05:06:55'),
(39, 'aed360b75826f379748a39622ee84db6c61b2a40', 'Joueur Inconnu', 0, 0, 0, 8, 1301, '2025-12-06 20:21:29'),
(40, '92acd0530db43d51658cad08333dfbf2dda03a11', 'Joueur Inconnu', 0, 0, 0, 4, 1168, '2025-12-06 20:21:35'),
(41, '934eca8f817998954effa79929b6b0042d6e4b16', 'John Doe', 0, 0, 0, 0, 66, '2025-12-08 05:30:06'),
(42, '5d016b639319000c4115a4360a7668dddc0d804c', 'l\'ancien micky', 45, 25, 0, 5, 1010, '2025-12-09 11:03:50'),
(43, '1e516e5fa4bf21fc750ffee18a7b96728802ec13', 'ADLER IDOLF', 1, 2, 0, 1, 60, '2025-12-09 12:53:01');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `gunfight_stats`
--
ALTER TABLE `gunfight_stats`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `identifier` (`identifier`),
  ADD KEY `idx_kills` (`kills` DESC),
  ADD KEY `idx_kd_ratio` (`kills`,`deaths`),
  ADD KEY `idx_last_played` (`last_played` DESC);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `gunfight_stats`
--
ALTER TABLE `gunfight_stats`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
