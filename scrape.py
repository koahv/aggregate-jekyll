from newspaper import Article
import sys,os

url=sys.argv[1]

# create an article object
article = Article(url)
article.download()
article.parse()
article.nlp()

title = article.title
link = article.url
#authors = article.authors
authors = ', '.join(article.authors)
#print("author:",AuthorString)
#date = article.publish_date.strftime("%Y-%m-%d")
#image = article.top_image
summary = article.summary.replace("\n", " ")
#text = article.text

print(f'Title: {title}')
print(f'Link: {link}')
print(f'Author: {authors}')
#print(f'Publish Date: {date}')
#print(f'Top Image: {image}')
print(f'Summary: ')
print(summary)


f = open("data.txt", "w")
f.write(authors + "\n" + title +"\n" + summary)

f.close()
