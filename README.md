Graph search for academic articles.

Authors: Aman Kapur and Jimmy Wu

Built at Olin College of Engineering as a part of an AI class.

The Vision
=====
Front-end: a graph database of indexed science journal articles.

Nodes are articles and authors.
Edges are articles-article, article-author, and author-author relations.

Article nodes hold metadata such as publication date, and subject category.
They also hold information to aid the search engine:
* abstract and full-text summarizations (automated)
* ranking factors, such as "importance" (number of other articles which cite this one)


Back-end: a search box with an auto-completion query grammar styled after Facebook's Graph Search interface

The user may toggle search heuristics.
Example: give preference to more obscure articles in the ranking function
