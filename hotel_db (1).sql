-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 15, 2026 at 12:25 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hotel_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancel_booking` (IN `p_booking_id` INT, OUT `p_result_message` VARCHAR(255))   BEGIN
    DECLARE v_room_id INT;
    DECLARE v_guests INT;
    DECLARE v_status VARCHAR(20);

    START TRANSACTION;

    SELECT room_id, guests, status INTO v_room_id, v_guests, v_status 
    FROM bookings WHERE id = p_booking_id;

    IF v_status = 'Cancelled' THEN
        SET p_result_message = 'FAILED: Booking is already cancelled.';
        ROLLBACK;
    ELSEIF v_room_id IS NOT NULL THEN
        UPDATE bookings SET status = 'Cancelled' WHERE id = p_booking_id;
        
        UPDATE rooms SET available = available + v_guests WHERE id = v_room_id;
        
        INSERT INTO audit_log (action, details) VALUES ('BOOKING_CANCELLED', CONCAT('Booking ID ', p_booking_id, ' cancelled. Restored ', v_guests, ' capacity.'));
        
        SET p_result_message = 'SUCCESS: Booking cancelled and capacity restored.';
        COMMIT;
    ELSE
        SET p_result_message = 'FAILED: Booking not found.';
        ROLLBACK;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_booking` (IN `p_user_id` INT, IN `p_room_id` INT, IN `p_amount` INT, IN `p_method` VARCHAR(50), IN `p_guests` INT, IN `p_adults` INT, IN `p_children` INT, IN `p_check_in` DATE, IN `p_check_out` DATE, OUT `p_result_message` VARCHAR(255))   BEGIN
    DECLARE v_avail INT;
    DECLARE v_room_number VARCHAR(10);
    DECLARE v_room_type VARCHAR(50);
    
    START TRANSACTION;

    SET v_avail = fn_check_room_availability(p_room_id, p_check_in, p_check_out);

    IF v_avail >= p_guests THEN
        SELECT number, type INTO v_room_number, v_room_type FROM rooms WHERE id = p_room_id;

        INSERT INTO bookings (user_id, room_id, room_number, room_type, amount, method, guests, adults, children, check_in, check_out, status)
        VALUES (p_user_id, p_room_id, v_room_number, v_room_type, p_amount, p_method, p_guests, p_adults, p_children, p_check_in, p_check_out, 'Verified');

        UPDATE rooms SET available = available - p_guests WHERE id = p_room_id;

        INSERT INTO audit_log (action, details) VALUES ('BOOKING_CREATED', CONCAT('User ', p_user_id, ' booked room ', v_room_number));

        SET p_result_message = 'SUCCESS: Booking confirmed.';
        COMMIT;
    ELSE
        SET p_result_message = 'FAILED: Room does not have enough capacity for these dates.';
        ROLLBACK;
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_check_room_availability` (`p_room_id` INT, `p_check_in` DATE, `p_check_out` DATE) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE v_total_capacity INT;
    DECLARE v_booked_capacity INT;

    SELECT available INTO v_total_capacity FROM rooms WHERE id = p_room_id;
    
    SELECT COALESCE(SUM(guests), 0) INTO v_booked_capacity 
    FROM bookings 
    WHERE room_id = p_room_id 
    AND status IN ('Verified', 'Pending')
    AND (p_check_in <= check_out AND p_check_out >= check_in);

    RETURN v_total_capacity - v_booked_capacity;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL,
  `details` text DEFAULT NULL,
  `logged_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `room_id` int(11) DEFAULT NULL,
  `room_number` varchar(10) DEFAULT NULL,
  `room_type` varchar(50) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `method` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'Verified',
  `guests` int(11) DEFAULT NULL,
  `adults` int(11) DEFAULT NULL,
  `children` int(11) DEFAULT NULL,
  `check_in` date DEFAULT NULL,
  `check_out` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `user_id`, `room_id`, `room_number`, `room_type`, `amount`, `method`, `status`, `guests`, `adults`, `children`, `check_in`, `check_out`, `created_at`) VALUES
(15, 17, 1, '101', 'Standard', 3500, 'Bkash', 'Verified', 1, 1, 0, '2026-09-16', '2026-09-21', '2026-09-13 12:38:52'),
(16, 17, 1, '101', 'Standard', 3500, 'Bkash', 'Verified', 1, 1, 0, '2026-09-24', '2026-09-28', '2026-09-13 13:36:25'),
(17, 18, 4, '202', 'Deluxe', 5500, 'Visa/Mastercard', 'Verified', 1, 1, 0, '2026-09-16', '2026-09-22', '2026-09-13 13:51:10'),
(18, 19, 3, '201', 'Deluxe', 5500, 'Bkash', 'Verified', 1, 1, 0, '2026-09-16', '2026-09-22', '2026-09-14 08:20:02'),
(19, 20, 1, '101', 'Standard', 3500, 'Bkash', 'Verified', 2, 1, 1, '2026-09-16', '2026-09-24', '2026-09-14 08:27:54'),
(20, 7, 3, '201', 'Deluxe', 5500, 'Bkash', 'Verified', 1, 1, 0, '2026-09-24', '2026-09-29', '2026-09-14 09:03:12');

-- --------------------------------------------------------

--
-- Table structure for table `damages`
--

CREATE TABLE `damages` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `room_number` varchar(10) DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` varchar(20) DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `receiver_id` int(11) DEFAULT NULL,
  `text` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `requests`
--

CREATE TABLE `requests` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `text` text DEFAULT NULL,
  `status` varchar(20) DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `requests`
--

INSERT INTO `requests` (`id`, `user_id`, `type`, `text`, `status`, `created_at`) VALUES
(1, 2, 'transport', 'Airport pickup for Room 301 at 2026-09-19T02:48', 'Pending', '2026-09-03 20:52:11'),
(2, 2, 'transport', 'Airport pickup for Room 301 at 2026-09-19T02:48', 'Pending', '2026-09-03 20:52:17'),
(3, 2, 'transport', 'Airport pickup for Room 301 at 2026-09-19T03:11', 'Pending', '2026-09-03 21:11:04'),
(4, 2, 'wheelchair', 'Wheelchair for Room 301', 'Pending', '2026-09-09 19:27:41'),
(5, 2, 'wheelchair', 'Wheelchair for Room 301', 'Pending', '2026-09-09 20:38:34'),
(6, 3, 'food', 'Food (Burger) for Room 301', 'Pending', '2026-09-09 20:40:06'),
(7, 2, 'transport', '101at 10:00 am', 'Pending', '2026-09-09 22:32:03'),
(8, 3, 'laundry', '101at 10:00 am', 'Pending', '2026-09-09 22:33:09'),
(9, 16, 'special', 'Extra pillow', 'Pending', '2026-09-12 22:38:56'),
(10, 17, 'special', 'Extra pillow', 'Pending', '2026-09-13 12:57:33');

--
-- Triggers `requests`
--
DELIMITER $$
CREATE TRIGGER `trg_after_request_insert` AFTER INSERT ON `requests` FOR EACH ROW BEGIN
    INSERT INTO audit_log (action, details) 
    VALUES ('NEW_REQUEST', CONCAT('User ', NEW.user_id, ' requested ', NEW.type, ': ', NEW.text));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `text` text DEFAULT NULL,
  `rating` int(11) DEFAULT 5,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `user_id`, `booking_id`, `text`, `rating`, `created_at`) VALUES
(1, 10, 4, 'It is a nise room', 5, '2026-09-09 19:10:34'),
(2, 11, 5, 'it is nise room', 5, '2026-09-09 19:13:17'),
(3, 12, NULL, 'This room is like how i axpected', 5, '2026-09-09 19:26:36'),
(4, 14, NULL, 'It is a nise room', 5, '2026-09-09 21:30:34'),
(5, 15, 9, 'This a very comfortable room', 5, '2026-09-09 22:30:43'),
(6, 9, 13, 'it was a nise room', 5, '2026-09-10 00:17:43'),
(7, 16, 14, 'This is really a nise room', 5, '2026-09-12 22:38:33'),
(8, 17, 15, 'it\'s a good room', 5, '2026-09-13 12:57:56'),
(9, 18, 17, 'It\'s a nise room', 5, '2026-09-13 13:51:33'),
(10, 19, 18, 'It is a good room', 5, '2026-09-14 08:20:37');

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `id` int(11) NOT NULL,
  `number` varchar(10) NOT NULL,
  `type` varchar(50) NOT NULL,
  `price` int(11) NOT NULL,
  `guests` int(11) NOT NULL,
  `available` int(11) NOT NULL,
  `amenities` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`id`, `number`, `type`, `price`, `guests`, `available`, `amenities`, `description`, `image`) VALUES
(1, '101', 'Standard', 3500, 2, 5, 'Free WiFi, AC, Flat-screen TV', 'A comfortable standard room with modern amenities.', 'https://images.unsplash.com/photo-1631049307264?w=800'),
(2, '102', 'Standard', 3500, 2, 3, 'Free WiFi, AC, Flat-screen TV', 'A cozy standard room with all essential amenities.', 'https://images.unsplash.com/photo-1611892440504?w=800'),
(3, '201', 'Deluxe', 5500, 3, 4, 'Free WiFi, AC, Minibar, City View', 'A spacious deluxe room with premium furnishings.', 'https://images.unsplash.com/photo-1590490360182?w=800'),
(4, '202', 'Deluxe', 5500, 3, 2, 'Free WiFi, AC, Minibar, City View', 'An elegant deluxe room with luxury amenities.', 'https://images.unsplash.com/photo-1566665797739?w=800'),
(5, '301', 'Presidential Suite', 12000, 4, 1, 'Free WiFi, AC, Minibar, City View, Jacuzzi', 'Our most luxurious suite.', 'https://images.unsplash.com/photo-1582719478250?w=800'),
(6, '101', 'Standard', 3500, 2, 5, 'Free WiFi, AC, Flat-screen TV', 'A comfortable standard room.', 'https://images.unsplash.com/photo-1631049307264?w=800'),
(7, '102', 'Standard', 3500, 2, 3, 'Free WiFi, AC, Flat-screen TV', 'A cozy standard room.', 'https://images.unsplash.com/photo-1611892440504?w=800'),
(8, '201', 'Deluxe', 5500, 3, 4, 'Free WiFi, AC, Minibar, City View', 'A spacious deluxe room.', 'https://images.unsplash.com/photo-1590490360182?w=800'),
(9, '202', 'Deluxe', 5500, 3, 2, 'Free WiFi, AC, Minibar, City View', 'An elegant deluxe room with luxury amenities.', 'https://images.unsplash.com/photo-1566665797739?w=800'),
(10, '301', 'Presidential Suite', 12000, 4, 1, 'Free WiFi, AC, Minibar, City View, Jacuzzi', 'Our most luxurious suite.', 'https://images.unsplash.com/photo-1582719478250?w=800');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','receptionist','customer','roomservice') DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `username`, `password_hash`, `role`, `created_at`) VALUES
(1, 'Admin', 'admin@hotel.com', 'admin', '$2y$10$H1wc4UENbyA0n5TwMUCyX.XHbEHXftruKL9Z3iP8yFnMeiBTYRQ7C', 'admin', '2026-09-03 15:22:31'),
(2, 'Receptionist', 'reception@hotel.com', 'receptionist', '$2y$10$itZOfoBiwn/D3fJUb22aB.rQSAy3tMxkqID8sfZnobvT44tokghOK', 'receptionist', '2026-09-03 15:22:31'),
(3, 'Room Service', 'roomservice@hotel.com', 'roomservice', '$2y$10$itZOfoBiwn/D3fJUb22aB.rQSAy3tMxkqID8sfZnobvT44tokghOK', 'roomservice', '2026-09-03 15:22:31'),
(5, 'Akash Abdullah', 'akash22@gmail.com', 'Akash Abdullah', '$2y$10$rsUO5ATb4WIL0UqqEkhsQ.RWW0c4bevRYk2YE49735cvUy4d5cYAu', 'customer', '2026-09-03 16:06:10'),
(6, 'David Smith', 'david@gmail.com', 'David Smith', '$2y$10$AY9owjb9iYrYsuSSWlZd0e2S8RGYh8/5/yLzwKDgytRhhdkVyLnDy', 'customer', '2026-09-03 16:19:46'),
(7, 'Tauhid Alom', 'tauhid@gmail.com', 'Tauhid', '$2y$10$fjv3h4BbrYB4yL1.fx9XF.dlxxz9wIo9CLYWLJwkIN0uF.uc3NHPu', 'customer', '2026-09-09 15:38:16'),
(8, 'Kamal Hossain', 'kamal@gmail.com', 'Kamal', '$2y$10$oWCJX9OyuOjtY9cZmhbu/OseYDIHSTkfpqyi0MPThUfmC6QENIpJG', 'customer', '2026-09-09 17:59:46'),
(9, 'Emon Chowdhury', 'emon@gmai.com', 'Emon', '$2y$10$5BW0a8eRpv4fnVBJZ/Z8EugpqbwdDDn4GW.bG5pQujR36uDithGEK', 'customer', '2026-09-09 18:18:33'),
(10, 'Ashfaq', 'ashfaq@gmail.com', 'Ashfaq', '$2y$10$Tn3cNB2bPY8w8TJp0Uv3AuoBPy3Ga0KLXlgdlsAIOWWf1A7YI7nne', 'customer', '2026-09-09 19:09:45'),
(11, 'Latif Hasan', 'latif@gmail.com', 'Latif', '$2y$10$1wz3o9S/690tYyKxktMCe.pmvFj4HFq5iHbqBFqxy8osve92KVt1i', 'customer', '2026-09-09 19:12:04'),
(12, 'Akbor Ali', 'akbor@gmail.com', 'Akbor', '$2y$10$O1zdhLE6QuqD660j5Kxhve7cMpLLrMiQZYgieeXI2nh1yeR552gCi', 'customer', '2026-09-09 19:25:35'),
(13, 'Badol Ahmed', 'badol@gmail.com', 'Badol', '$2y$10$Wf6wQikMI4wcgXqsy7PaVuHDOLmL2y/lxEX5m0RJcRbKXTqSkqdvK', 'customer', '2026-09-09 20:55:24'),
(14, 'Shofik Uddin', 'shofik@gmail.com', 'Shofik', '$2y$10$/0tBdjkvV2g/hPFXSyX49Og912s9rRD5b5cH3HPPyd0/Ji/nE6Jiy', 'customer', '2026-09-09 21:29:46'),
(15, 'Rahim Uddin', 'rahim@gmail.com', 'Rahim', '$2y$10$kGFX8OFo7XCc5zLbaPAnl.EsVuGV4R316L5dcu9yc2Zq/Q2orn/1u', 'customer', '2026-09-09 22:29:25'),
(16, 'Sadik Hasan', 'sadik@gmail.com', 'Sadik', '$2y$10$IaWchPJhDUt1jCL6EzDA2uZfOwe8lYC0hx5ZRFb9fEXGdMDkuzunm', 'customer', '2026-09-12 22:37:40'),
(17, 'Jon Doe', 'jon@gmail.com', 'Jon', '$2y$10$hFLPGADUmcuBqNkNQrsuY..7X6CxTIs5ARzDA2/EUdfZv4jDLmc7C', 'customer', '2026-09-13 12:34:52'),
(18, 'Miceal Collins', 'miceal@gmail.com', 'Miceal', '$2y$10$EH2gsqBkOFpQ5rENsURkEOLpkNo0wvns7NNe0kmAhMPmUXveDn3Tq', 'customer', '2026-09-13 13:50:38'),
(19, 'Akib Hossain', 'akib@gmail.com', 'Akib', '$2y$10$XtIl1N.peouSXmrR6L3qEuYikXECND/1.iVftSxHcp5zHEztTQ/ai', 'customer', '2026-09-14 08:19:16'),
(20, 'tt', 'gggg@gmail.com', 'tt', '$2y$10$YnnBCf8HhbBcbuHu6lS4EOioGbAJvRPuFI86iT43.IXeHGLZtHHGO', 'customer', '2026-09-14 08:26:21');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `bookings_ibfk_2` (`room_id`);

--
-- Indexes for table `damages`
--
ALTER TABLE `damages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `requests`
--
ALTER TABLE `requests`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `damages`
--
ALTER TABLE `damages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `requests`
--
ALTER TABLE `requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
