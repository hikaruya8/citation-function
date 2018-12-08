ARC_DIR=/shared/0/datasets/ACL-ARC/data/
AAN_DIR=../aan
ARC_JSON_DIR=../json

# This is the directory that will contain the feature vectors for each citation
# in the ARC JSON data
ARC_FTR_DIR=../working-dir/arc-ftrs/
FEATURE_VEC_DIR=../working-dir/feature-vecs/
CLASSIFIER_FILE=../working-dir/function-classifier.pkl

# If you want to go from the *very* beginning, you need to download the ARC and
# then convert it to JSON.  Or you can just download the version we made
if [ ! -d "$ARC_DIR" ] ; then
    #TODO: Prompt the user to check the user wants to execute this command
    
    #wget --no-parent --recursive \
    #     http://acl-arc.comp.nus.edu.sg/archives/acl-arc-160301-parscit

    # TODO: automatically clean up the unneeded download stuff
    echo -n ''
fi

if [ ! -d "$AAN_DIR" ] ; then
    echo "You need to download the ACL Anthology Network; Please register for"
    echo "the download at http://aan.how/index.php/home/download#aanNetworkCorpus "
    echo "and then update the AAN_DIR variable in this script"
    return
fi

# Canonicalize all the outgoing citations in the ARC, which resolves external
# IDs to a single entity
#
# NOTE: due to a bad design decision and iterative development; this process
# relies on the converted JSON files, which in turns relies on the output of
# this process.  Originally, the JSON was produced without integrating all the
# Citation IDs directly into it, but then this program was improved and the JSON
# was regenerated at which point ID integration was added, thereby creating an
# impossible loop.  We've added the output of this program already to the repo,
# but regenerating this part from scratch would require backing out the JSON
# integration or some kind of two-phase JSON creation :(
if [ ! -e "../resources/arc-paper-ids.tsv" ] ; then
    #python canonicalize_citations.py \
    #       ../resources/arc-paper-ids.tsv \
    #       ../resources/arc-citation-network.tsv
    echo -n ''
fi

# Convert the XML formatted text to JSON, with resolved citation contexts
if [ ! -d "$ARC_JSON_DIR" ] ; then
    echo 'Converting XML to JSON; Make sure you have a core NLP server running'
    #python convert_ARC_xml_to_json.py $ARC_DIR $ARC_JSON_DIR
fi

# Convert Teufel's data to the JSON format
#python convert_teufel_data.py ../data/teufel-json

# Integrate the BRAT annotations into the json data
#python integrate_annotations.py ../data/annotated-json-data

# Generates a text corpus of citances and citance IDs to feed into Mallet for
# topic modeling
#python generate_mallet_corpus.py ../working-files/

# Generate the actual .mallet files
#./gen-mallet.sh

# Train the LDA Model
#./train-mallet-models.sh

# Weight each cited paper based on its centrality, PageRank, etc. in the
# citation network
# python compute_temporal_weights.py ../working-files/arc-paper-ids.2.tsv ../working-files/arc-network-weights.tsv

# Generate the training data
python generate_training_data.py $FEATURE_VEC_DIR

# Run cross-validation to see how well things did
python run_topic_cv.py ../working-dir/feature-vecs/

# If everything looks good, train the classifier
python train_classifier.py $FEATURE_VEC_DIR $CLASSIFIER_FILE

# Use the features found by the training data to covert the ARC into feature vectors
python convert_ARC_to_features.py $ARC_JSON_DIR $FEATURE_VEC_DIR $ARC_FTR_DIR 

# Classify everything.  The "build graph" refers to building the fully-labeled
# citation graph with citation functions.
./build-graph.sh

