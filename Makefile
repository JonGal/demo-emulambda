# Make sure this profile has Lambda loading and execution permissions
LAMBDA_PROFILE=Matt-Lab-Dev
#Make sure this is correct for KMS and Lambda
#Keep them the same region for performance!
REGION=us-west-2


#Deliverable
SRC=test-perms.py
ZIP=zip
ZIPOPTIONS=-r
ZIPFILE=test-perms.zip
LAMBDA=test-perms

#Role the Lambda will execute with
# make sure the profile you are executing with
# is allowed to assume this role. Make sure you do this by 
# changing the Trust Policy for the role
ROLE=arn:aws:iam::882417160631:role/service-role/bloofer

#Flags
#Flag for updating Lambda
LAMBDA_DELIVERED=lambda_delivered
LAMBDA_TESTED=lambda_tested
LAMBDA_ROLE_TESTED=lambda_role_tested





$(ZIPFILE) : $(SRC) $(LIBS) all_tests
	$(ZIP) $(ZIPOPTIONS) $(ZIPFILE) $(SRC) $(LIBS)

$(LAMBDA_DELIVERED): $(ZIPFILE)
	aws lambda update-function-code --function-name $(LAMBDA) --zip-file fileb://$(ZIPFILE) --profile $(LAMBDA_PROFILE) --region $(REGION) && touch $(LAMBDA_DELIVERED)

$(LAMBDA): Makefile $(ZIPFILE) 

all: $(LAMBDA) $(LAMBDA_DELIVERED) 

# emulambda uses the [default] profile in credentials.
# This identity must have all the perms that the Lmbda will use
	# You are pointing to the file and functions you defined
	# the Handler area for the Lambda (the code below assumes the function is named
	# lambda_handler
	# #This make string is convoluted because emulambda currently doesn't return as shell error
	# status, soo we test for error and set the status successfule if an error exists,
	# meaning we should remove the success flag - Oh yeah, kludge baby
$(LAMBDA_TESTED): $(SRC) $(LIBS)
	emulambda -v $(LAMBDA).lambda_handler test-perms.json | tee /tmp/make_out.$$; grep -i error /tmp/make_out.$$ >/dev/null || touch lambda_tested

$(LAMBDA_ROLE_TESTED): $(SRC) $(LIBS)
	emulambda -v $(LAMBDA).lambda_handler test-perms.json -r $(ROLE) | tee /tmp/make_out.$$; grep -i error /tmp/make_out.$$ >/dev/null || touch lambda_role_tested

all_tests: $(LAMBDA_TESTED) $(LAMBDA_ROLE_TESTED)

