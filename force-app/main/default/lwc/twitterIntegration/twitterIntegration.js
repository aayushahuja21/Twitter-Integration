import { LightningElement, track} from 'lwc'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import postTweet from '@salesforce/apex/TwitterController.postTweet';
import deleteTweet from '@salesforce/apex/TwitterController.deleteTweet';
import getUserDetails from '@salesforce/apex/TwitterController.getUserDetails';
import postMediaTweet from '@salesforce/apex/TwitterController.postMediaTweet';
 
export default class TwitterIntegration extends LightningElement {
    usersData;
    tweetMessage;
    deleteTweetId;
    isButtonClicked;
    selectedTweetType;
    isLoading = false;
    @track uploadedFile;
    tweetMessageWithMedia;
    isDeleteModalOpen = false;        
    isPostTweetSelected = false;    
    isPostTweetModalOpen = false;
    isSimpleTweetSelected = false;
    isSimpleTweetSelected = false;
    isTweetWithMediaSelected = false;
    isGetUserDetailsModalOpen = false;
    @track modalHeading = 'Simple Tweet';

    get acceptedFormats() { 
        return ['.png','.jpg','.jpeg']; 
    } 

    get tweetOptions() {
        return [
            { label: 'Simple Tweet', value: 'simpleTweet' },
            { label: 'Tweet with Media', value: 'tweetWithMedia' }
        ];
    }

    // Generic method to display toast messages
    showToast(title, message, variant, url) {
        const messageData = url ? [{
            url: 'https://twitter.com/aayushahuja21/status/' + url + '/',
            label: 'See Tweet'
        }] : null;
    
        this.dispatchEvent(
            new ShowToastEvent({
                title: url ? 'Success' : title,
                message: url ? message + ' {0}' : message,
                messageData: messageData,
                variant: url ? 'success' : variant,
            })
        );
    }
    

    //POST Tweet...
    handleTweetTypeChange(event) {
        this.selectedTweetType = event.detail.value;
        console.log(this.selectedTweetType);
    }   

    handleTweetMessageChange(event) {
        this.tweetMessage = event.detail.value;
        console.log(this.tweetMessage);
    }

    handleUploadFinished(event) {
        this.uploadedFile = event.target.files[0];
        console.log('uploadedFile',this.uploadedFile);
    } 

    handlePostTweet() {
        this.isLoading = true;

        this.isButtonClicked = true;
        this.isPostTweetModalOpen = true;

        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }

    handlePostTweetButton() {
        this.isLoading = true; 
        console.log('tweetMessage:', this.tweetMessage);
        this.tweetMessageWithMedia = this.tweetMessage;

        if (this.selectedTweetType === 'simpleTweet') {
            if (!this.tweetMessage) {
                this.showToast('Error', 'Tweet message cannot be empty!', 'error', null);

                setTimeout(() => {
                    this.isLoading = false;
                }, 500);
                return;
            }
            postTweet({ tweetMessage: this.tweetMessage, mediaId: null })
                .then(result => {
                    console.log(result);
                    result = JSON.parse(result);

                    console.log('https://twitter.com/aayushahuja21/status/' + result.data.id + '/');        
                    this.showToast('Success', 'Tweet Posted Successfully!', 'success', result.data.id);
                })
                .catch(error => {
                    console.error('Error:', error);
                    this.showToast('Error', 'An error occurred while posting the tweet: ' + error, 'error', null);
                })
        } 
        else if (this.selectedTweetType === 'tweetWithMedia') {
            if (!this.uploadedFile) {
                this.showToast('Error', 'Media cannot be empty!', 'error', null);
                this.tweetMessage = '';

                setTimeout(() => {
                    this.isLoading = false;                    
                }, 500);
                return;
            }
            // Convert to base64 and send converted string to apex
            var reader = new FileReader();
            console.log(this.tweetMessage);
            reader.onload = () => {
                const base64File = reader.result.split(',')[1];
        
                postMediaTweet({ tweetMessage: this.tweetMessageWithMedia, blobMediaString: base64File })
                    .then(result => {
                        console.log(result);
                        result = JSON.parse(result);
                        console.log('https://twitter.com/aayushahuja21/status/' + result.data.id + '/');
                        this.showToast('Success', 'Tweet Posted Successfully!', 'success', result.data.id);
                    })
                    .catch(error => {
                        console.error('Error:', error);
                        this.showToast('Error', 'An error occurred while posting the tweet: ' + error, 'error', null);
                    })
            };
            reader.readAsDataURL(this.uploadedFile);
        }

        setTimeout(() => {
            this.isLoading = false; 
            this.isPostTweetSelected = false;
        }, 4000);
        
        this.uploadedFile='';
        this.tweetMessage = '';
        this.selectedTweetType='';
        this.isButtonClicked = false;
        this.isPostTweetModalOpen = false;
        this.isTweetWithMediaSelected = false;
    }
    
    

    // DELETE Tweet...
    handleDeleteTweet() {
        this.isLoading = true;
        this.isButtonClicked = true;
        this.isDeleteModalOpen = true;

        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }     

    handleDeleteTweetIdChange(event) {
        this.deleteTweetId = event.detail.value;
    }

    handleDeleteTweetButton() {
        if (!this.deleteTweetId) {
            this.showToast('Error', 'Tweet Id cannot be Empty!', 'error', null);
        } else {
            this.isLoading = true; // Set isLoading to true to show spinner
            deleteTweet({ tweetId: this.deleteTweetId })
                .then(result => {
                    console.log(result);
                    if (result === '200') {
                        this.showToast('Success', 'Tweet deleted Successfully!', 'success', null);
                        this.isDeleteModalOpen = false;
                    } else {
                        this.showToast('Error', 'Id value is not valid!', 'error', null);
                    }
                })
                .catch(error => {  
                    console.error('Error:', error);
                    this.isDeleteModalOpen = false;
                    this.showToast('Error', 'An error occurred while deleting the tweet: ' + error, 'error', null);
                })
                .finally(() => {
                    this.isLoading = false;                     
                    this.deleteTweetId = '';                                        
                });
        }
    }   

    // GET User Details...
    handleGetUserDetails() {
        this.isLoading = true;
        this.isButtonClicked = true;
        this.isGetUserDetailsModalOpen = true;
    
        if (!this.usersData || this.usersData.length === 0) {
            getUserDetails()
                .then(result => {
                    this.usersData = JSON.parse(result);
                    console.log(JSON.stringify(this.usersData));
                })
                .catch(error => {
                    console.error('Error:', error);
                    this.showToast('Error', 'An error occurred while fetching user details: ' + error, 'error', null);
                });
        } else {
            console.log('Data already fetched:', JSON.stringify(this.usersData));
        }

        setTimeout(() => {
            this.isLoading = false;
        }, 2000);
    }
         
     
    // Previous, Next and Close Buttons...
    handlePrevious() {
        this.uploadedFile='';
        this.tweetMessage='';
        this.isLoading = true;
        this.isPostTweetModalOpen = true;
        this.isPostTweetSelected = false;
        this.modalHeading = 'Simple Tweet';
        this.isTweetWithMediaSelected = false;

        setTimeout(() => {
            this.isLoading = false;
        }, 500);
    }

    handleNext() {
        if(this.selectedTweetType) {
            this.isLoading = true;
            this.isPostTweetSelected = true;
            this.isPostTweetModalOpen = false;

            if(this.selectedTweetType == 'tweetWithMedia') {
                this.modalHeading = 'Tweet With Media';
                this.isTweetWithMediaSelected = true;
            }

            setTimeout(() => {
                this.isLoading = false;
            }, 500);
        }
        else {
            this.showToast('Error', 'Please Select Tweet Type', 'error', null);
            console.error('Please Select Tweet Type');
        }
    }   

    closeModal() {
        this.tweetMessage = '';
        this.deleteTweetId = '';
        this.selectedTweetType='';
        this.isButtonClicked = false;
        this.isDeleteModalOpen = false;
        this.handleGetUserDetails = false;
        this.isPostTweetModalOpen = false;
        this.isGetUserDetailsModalOpen = false;
    }
}