-- Insert sample data into the films table
INSERT INTO public.films (code, title, did, date_prod, kind, len)
VALUES
  ('F001', 'The Shawshank Redemption', 1, '1994-09-23', 'Drama', '2 hours 22 minutes'),
  ('F002', 'The Godfather', 2, '1972-03-24', 'Crime', '2 hours 55 minutes'),
  ('F003', 'The Dark Knight', 3, '2008-07-18', 'Action', '2 hours 32 minutes'),
  ('F004', 'Pulp Fiction', 4, '1994-10-14', 'Crime', '2 hours 34 minutes'),
  ('F005', 'Schindler''s List', 5, '1993-12-15', 'Biography', '3 hours 15 minutes');

-- Insert sample data into the distributors table
INSERT INTO public.distributors (name, film_id)
VALUES
  ('Warner Bros.', 1),
  ('Paramount Pictures', 2),
  ('Warner Bros.', 3),
  ('Miramax', 4),
  ('Universal Pictures', 5);