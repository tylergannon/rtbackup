USE `my_test_app`;

delete from my_data where id between 30 and 50;

update my_data set value = CONCAT(value, ' FoobZ')
where id between 20 and 60;

-- After this, data set should look like:
-- +----+---------------------------+
-- | id | value                     |
-- +----+---------------------------+
-- |  1 | Berk Fuentes              |
-- |  2 | Phoebe M. Harvey          |
-- |  3 | Cole Q. Buck              |
-- |  4 | Lev Q. Vazquez            |
-- |  5 | Marcia Knapp              |
-- |  6 | Malcolm J. Bolton         |
-- |  7 | Lawrence Cox              |
-- |  8 | Aurelia Anthony           |
-- |  9 | Benjamin Schmidt          |
-- | 10 | Martin Beard              |
-- | 11 | Miriam Serrano            |
-- | 12 | Dennis I. Sims            |
-- | 13 | Cody S. Melton            |
-- | 14 | Cullen Silva              |
-- | 15 | Kylee A. Pruitt           |
-- | 16 | Minerva K. Hester         |
-- | 17 | Neil Crawford             |
-- | 18 | Alexis Walton             |
-- | 19 | Evan B. Justice           |
-- | 20 | Carissa Pollard FoobZ     |
-- | 21 | Samantha H. Bridges FoobZ |
-- | 22 | Xerxes Fry FoobZ          |
-- | 23 | Winter Crawford FoobZ     |
-- | 24 | Imogene Jacobs FoobZ      |
-- | 25 | Kimberly Rhodes FoobZ     |
-- | 26 | Tate E. Taylor FoobZ      |
-- | 27 | Steel Stevens FoobZ       |
-- | 28 | Conan Cleveland FoobZ     |
-- | 29 | Emerson Owen FoobZ        |
-- +----+---------------------------+