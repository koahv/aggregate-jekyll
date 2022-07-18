import sys,os
from newspaper import Article
from sumy.utils import get_stop_words
from sumy.nlp.stemmers import Stemmer
from sumy.nlp.tokenizers import Tokenizer
from sumy.parsers.plaintext import PlaintextParser
from sumy.summarizers.lex_rank import LexRankSummarizer as Summarizer

url=sys.argv[1]

LANGUAGE = "english"

# configurable number of sentences
SENTENCES_COUNT = 5

article = Article(url)
article.download()
article.parse()

# text cleaning
text = "".join(article.text).replace("\n", " ").replace('"', "")
parser = PlaintextParser.from_string(text, Tokenizer(LANGUAGE))
stemmer = Stemmer(LANGUAGE)

summarizer = Summarizer(stemmer)
summarizer.stop_words = get_stop_words(LANGUAGE)

article_summary = []
for sentence in summarizer(parser.document, SENTENCES_COUNT):
    article_summary.append(str(sentence))

clean_summary = ' '.join([str(elem) for elem in article_summary])

title = article.title

link = article.url

authors = ', '.join(article.authors)

#print(f'Title: {title}')
#print(f'Link: {link}')
#print(f'Author: {authors}')
#print(clean_summary)

# write to file
a = open("author.txt", "w")
#a.write(authors + "\n" + title +"\n" + summary)
a.write (authors)
a.close()

b = open("title.txt", "w")
b.write(title)
b.close

c = open("summary.txt", "w")
c.write(clean_summary)
c.close()
