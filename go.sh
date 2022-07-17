#!/bin/bash

# configuration
jekyll_post_dir="<jekyll_dir>/_posts"
api_key_loc="<location of file containing TextRazor API key>"

newspaper3k(){

    # send link to newspaper3k
    article_data=$(python scrape.py $link)

    # assign each line in data.txt to array
    readarray data < data.txt

    # for each value in array
    for ((i = 0; i < ${#data[@]}; ++i)); do

        # check if value is null
        if [  "${data[i]}" = $'\n' ]; then

            # if value is null, assign text "unknown" to value
            data[i]="unknown"

        fi

    done

    # put array into identified vars
    Author=${data[0]}
    Title=$(echo "${data[1]}" | tr -d '[\n]')
    Summary=${data[2]}
    Date=$(date '+%Y-%m-%d')

    # output info
    echo "author: $Author";echo;echo
    echo "Title: $Title";echo;echo
    echo "Summary: $Summary";echo;echo
    echo "Link: $link";echo;echo

}


textrazor(){

    api_key_value=`cat $api_key_loc`

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

        echo "Category set to $categories"

        # create url friendly post name
        mod_url="$(echo -e "${Title}" | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)"

        # reformat category input
        mod_categories="$(echo -e "$categories" | sed 's/ /\n- /g;1s/^/- /')"

        # generate filename
        mod_filename="$Date-$mod_url"

        echo "Filename: $mod_filename"

        # generate summary string
    	mod_summary="$(echo -e "#### Summary\\n>$Summary")"

        echo "$mod_summary"

        # generate tags string
		mod_tags="$(echo -e "tags: [$extracted_tags]"  | sed -z 's/\n/,/g;s/,$/\n/')"

        # write post
        echo -e "---\\nlayout: post\\ntitle: \"$Title\"\\ndate: $Date\\ncategories:\\n$mod_categories\\nauthor: $Author\\n$mod_tags\\n---\\n\\n\\n$mod_summary\\n\\n[Visit Link]($link){:target=\"_blank\" rel=\"noopener\"}\\n\\n" > $jekyll_post_dir/$mod_filename.md

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
