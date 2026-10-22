# Umami

Umami is web analytics you run yourself: how many people visit, which pages they read, where they came from, which countries and devices. It does that without cookies and without collecting personal data, so there's no consent banner to show, and the numbers are yours.

### What people use it for

- An alternative to Google Analytics for a website, a blog or a product.
- Several sites in one place, each with its own dashboard, shared by link if you like.
- Counting events (signups, button clicks, downloads) with a line of JavaScript.

### Good to know

- It keeps its data in its own Postgres database, with a snapshot every day, and stays awake so no page view is missed.
- Add a site in Umami, then put the script tag it gives you on that site.
- The first login is `admin` / `umami`: change the password straight away.
