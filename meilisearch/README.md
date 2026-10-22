# Meilisearch

Meilisearch is a search engine you put behind a search box. You send it your records (products, articles, documents) as JSON, and it answers searches in milliseconds, forgiving typos, ranking the best matches first, with filters and facets for narrowing down.

### What people use it for

- Search on a shop, a docs site, a blog or an app's own data.
- "Search as you type" boxes that answer on every keystroke.
- Filtering and sorting large lists (by price, tag or date) without writing that in SQL.

### Good to know

- It's one service with its data on a volume. The master key is generated for you; create search-only keys from it for browsers.
- Your app keeps the data in its own database and sends changes to Meilisearch, which keeps its index up to date.
- The version is pinned, because a new major version needs its data moved over.
