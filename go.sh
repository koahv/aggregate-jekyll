#!/bin/bash

# configuration
jekyll_post_dir="/home/z0/cbdinfo/_posts"
api_key_loc="/home/z0/.textrazorapi.key"

newspaper3k(){

    # send link to newspaper3k
    article_data=$(python scrape.py $link;)

    Date=$(date '+%Y-%m-%d')

    sed -n '2{s/^$/unknown/;s/^/author: /;p;q;}' author.txt

    Author=$(cat author.txt)
    Title=$(cat title.txt)
    Summary=$(cat summary.txt)

    # output info
    echo "author: $Author";echo;echo
    echo "Title: $Title";echo;echo
    echo "Summary: $Summary";echo;echo
    echo "Link: $link";echo;echo

}


textrazor(){

    api_key_value=$(cat $api_key_loc)

    echo "Fetching data from TextRazor API...";echo

    # store json api response to var
    response=$(curl -X POST \
        -H "x-textrazor-key: $api_key_value" \
        -d "extractors=topics" \
        -d "url=$link" \
        https://api.textrazor.com/ | jq -r '.response.topics')
    #echo $response

    echo;echo "Processing keywords...";echo

    # clear output file
    > extracted_tags.txt

    # decode json
    for line in $(echo "${response}" | jq -r '.[] | @base64'); do

        request() {

            echo ${line} | base64 --decode | jq -r ${1}

		}

        # set extracted json values to vars
        label=$(request '.label')
        score=$(request '.score')

            # if topic relevance is 1
            if [[ "$score" = 1 ]]; then

                # write topics to file
                echo -e "$label" >> extracted_tags.txt

            fi

    done

    # trim topics
    extracted_tags=`cat extracted_tags.txt | tr -dc '[:alnum:]\n\r ()-'`

    # output result
    echo;echo "keywords:";echo

    echo "$extracted_tags";echo;echo

}


create_post(){

    # retrieve category specification from user
    read -p $'Enter Categories (space-separated)\n' categories; echo;echo

    # user verification
    read -p "Is $categories correct? (Y/y)" -n 1 -r; echo

    # if verified
    if [[ $REPLY =~ ^[Yy]$ ]]; then

        sorted_categories=$(echo $categories | xargs -n1 | sort | xargs)

        echo "Categories set to: $sorted_categories"

        # create url friendly post name
        mod_url="$(echo -e "${Title}" | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)"

        # reformat category input
        mod_categories="$(echo -e "$sorted_categories" | sed 's/ /\n- /g;1s/^/- /')"

        # generate filename
        mod_filename="$Date-$mod_url"

        echo "Filename: $mod_filename"

        # generate summary string
    	mod_summary="$(echo -e "#### Summary\\n>$Summary")"

        echo "$mod_summary"

        # generate tags string
		mod_tags="$(echo -e "tags: [$extracted_tags]"  | sed -z 's/\n/,/g;s/,$/\n/')"

        # write post
        echo -e "---\\nlayout: post\\ntitle: \"$Title\"\\ndate: $Date\\ncategories:\\n$mod_categories\\nauthor: $Author\\n$mod_tags\\n---\\n\\n\\n$Summary\\n\\n[Visit Link]($link){:target=\"_blank\" rel=\"noopener\"}\\n\\n" > $jekyll_post_dir/$mod_filename.md

    else

        #if user input!=Yy return to user input
        create_post

    fi

}


main(){

    echo "Enter Link"

    # accept input for specified url
    read link

    # call newspaper3k function
    newspaper3k

    echo;echo

    # call textrazor function
    textrazor

    # call create_post function
    create_post
}

main
