const functions = require('firebase-functions');
// const spawn = require('child-process-promise').spawn;
const path = require('path');
const os = require('os');
const fs = require('fs');
// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

function send(message) {
    // Send a message to the device corresponding to the provided
    // registration token.
    console.log("BEGIN SENDING MESSAGE");
    admin.messaging().send(message)
        .then((response) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', response);
            return;
        })
        .catch((error) => {
            console.log('Error sending message:', error);
        });
}

function sendNotificationToDevice(fcmToken, message) {
    // Send a message to the device corresponding to the provided
    // registration token.
    console.log("BEGIN SENDING MESSAGE");
    admin.messaging().sendToDevice(fcmToken, message, {contentAvailable: true})
        .then((response) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', response);
            return;
        })
        .catch((error) => {
            console.log('Error sending message:', error);
        });
}

async function getUser(uid, store) {
    let user = await store.collection('users').doc(uid)
        .get()
        .then(doc => {
            if (!doc.exists) {
                let error = "Document does not exist!";
                throw error;
            } 
            return doc.data();
        })
        .catch(reason => {
            console.log(reason);
        })
    return user;
}

async function badgeCount(userId) {
    
    var db = admin.firestore();
    
    let count = db.collection("chats").where(`unread.${userId}`, "==", true)
        .get()
        .then((querySnapshot) => {
            return querySnapshot.size;
            
        })
        .catch((error) => {
            console.log("Error getting documents: ", error);
            return 0;
        })
    return count;
}

async function getDocs(ref) {
    let docs = await ref.get()
        .then((snapshot) => {
            return snapshot.docs;
        })
        .catch(reason => {
            console.log(reason);
        })

    return docs;
}

function createMessage(data, body, badge, sound) {
    return {
        // token: token,

        data: data,
        apns: {
            payload: {
                aps: {
                    'content-available': 1,
                    alert: {
                        body: body,
                        badge: badge,
                        categoryIdentifier: "wikio-ki",
                        sound: sound
                    },
                }
            }
        }
    }
}

// Listen for events

exports.observeNewMessage = functions.firestore
    .document('chats/{chatUid}').onUpdate((change, context) => {
        var chatUid = context.params.chatUid;
        // Get an object representing the document
        // e.g. {'name': 'Marie', 'age': 66}
        const chat = change.after.data();
  
        // ...or the previous value before this update
        const chatBefore = change.before.data();

        if (chatBefore.lastMessageSent === chat.lastMessageSent) {
            return;
        }
        
        const lastSenderUid = chat.lastSenderUid;
        const memberUids = chat.memberUids;
        const receiverUid = memberUids.filter(uid => uid !== lastSenderUid)[0];
                
        const store = admin.firestore();
        // Handle Push Notifications
        if (chat.isSending === false && chat.status === "DELIVERED") {
            
            let receiver = getUser(receiverUid, store);
            let sender = getUser(lastSenderUid, store);

            var badge = badgeCount(receiverUid);

            return Promise.all([receiver, sender, badge])
                .then(values => {
                    const receiver = values[0];
                    const sender = values[1];
                    const badge = values[2];

                    console.log(`Notification from ${sender.username}(${sender.uid}) to ${receiver.username}(${receiver.uid})`);
                    console.log("Sender display name:", sender.displayName);
                    const message = {
    
                        data: {
                            chat: chatUid,
                        },
                        notification: {
                            body: `from ${sender.username}`,
                            badge: `${badge}`,
                            sound: "default",
                        },
                    }

                    return sendNotificationToDevice(receiver.fcmToken, message);
                })
                .catch(reason => {
                    console.log(reason);
                })
        }  
});

// [START observeAddedUser]
exports.observeAddedUser = functions.firestore
    .document('/users/{uid}/friendRequests/{autoUid}')
    .onCreate((snap, context) => {

        var addedUid = context.params.uid;

        const data = snap.data();
        const requestUid = Object.keys(data)[0];

        // perform desired operations ...
        const store = admin.firestore();

        let added = getUser(addedUid, store);
        let requestedBy = getUser(requestUid, store);

        return Promise.all([added, requestedBy])
            .then(values => {
                const added = values[0];
                const requestedBy = values[1];

                console.log(`User: ${added.username}(${added.uid}) added by: ${requestedBy.username}(${requestedBy.uid})`);
                const message = {
    
                    data: {
                        requestedByUid: requestedBy.uid
                    },
                    notification: {
                        body: `${requestedBy.username} added you!`,
                        sound: "default",
                    },
                }

                console.log("message:", message);
                sendNotificationToDevice(added.fcmToken, message);


                return;
            })
            .catch(reason => {
                console.log(reason);
            })
    });
// [END observeAddedUser]

// [START observeDeleteChat]
exports.observeDeleteChat = functions.firestore
    .document('/chats/{chatUid}')
    .onDelete((snap, context) => {
        const chatUid = context.params.chatUid;
        const deletedChat = snap.data();
        const store = admin.firestore();
        const batch = store.batch();
        
        var promiseArray = [];
        
        console.log('BEGIN DELETE CHATS');

        for (let memberUid of deletedChat.memberUids) {
            const ref = store.collection('chats').doc(chatUid).collection(memberUid);
            const chatDocsForMember = getDocs(ref);
            promiseArray.push(chatDocsForMember);
        }
        // promiseArray
        Promise.all(promiseArray)
            .then(values => {
                const memberDocs0 = values[0];
                const memberDocs1 = values[1];
                for (let doc of memberDocs0) {
                    doc.ref.delete().then(() => {
                        console.log("Document successfully deleted!");
                        return
                      }).catch(function(error) {
                        console.error("Error removing document: ", error);
                      });   
                }

                for (let doc of memberDocs1) {
                    doc.ref.delete().then(() => {
                        console.log("Document successfully deleted!");
                        return
                      }).catch(function(error) {
                        console.error("Error removing document: ", error);
                      });   
                }
                return;
            })
            .catch(reason => {
                console.log(reason);
            })     
            
        batch.commit();
    });
// [END observeDeleteChat]

// [START observeLike]
exports.observeLike = functions.https.onCall((data, context) => {
    
    const uid = data.friendUid;
    const username = data.likedByUsername;
    const type = data.messageType;

    const message = {
        notification: {
            body: `${username} liked your ${type}`,
        }
    }

    const store = admin.firestore();

    // User to send notification to
    const user = getUser(uid, store);

    return Promise.all([user])
        .then(values => {
            const user = values[0];
            console.log(`${username} liked ${user.username}'s ${type}.`);
            return sendNotificationToDevice(user.fcmToken, message); 
        })
        .catch(reason => {
            console.log(reason);
            return reason;
        })
});
// [END observeLike]

// [START observeAcceptFriendRequest]
exports.observeAcceptFriendRequest = functions.https.onCall((data, context) => {

    const uid = data.friendUid;
    const username = data.acceptedByUsername;

    const message = {
        notification: {
            body: `You and ${username} are now friends!`
        }
    }

    const store = admin.firestore();

    // User to send notification to
    const user = getUser(uid, store);

    return Promise.all([user])
        .then(values => {
            const user = values[0];
            return sendNotificationToDevice(user.fcmToken, message); 
        })
        .catch(reason => {
            console.log(reason);
            return reason;
        })
});
// [END observeAcceptFriendRequest]

// [START observeCreateAccount]
// exports.observeCreateAccount = functions.firestore
    // .document('/users/{uid}')
    // .onCreate((snap, context) => {
    //     const uid = context.params.uid;
    //     const store = admin.firestore();

    //     const user = snap.data();
    //     const bucket = admin.storage().bucket();



        
    // });
// [END observeCreateAccount]

// [START generateThumbnail]
/**
 * When an image is uploaded in the Storage bucket We generate a thumbnail automatically using
 * ImageMagick.
 */
// [START generateThumbnailTrigger]
// exports.generateThumbnail = functions.storage.object().onFinalize(async (object) => {
//     // [END generateThumbnailTrigger]
//       // [START eventAttributes]
//       const fileBucket = object.bucket; // The Storage bucket that contains the file.
//       const filePath = object.name; // File path in the bucket.
//       const contentType = object.contentType; // File content type.
//       const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.
//       // [END eventAttributes]
    
//       // [START stopConditions]
//       // Exit if this is triggered on a file that is not an image.
//       if (!contentType.startsWith('image/')) {
//         return console.log('This is not an image.');
//       }
    
//       // Get the file name.
//       const fileName = path.basename(filePath);
//       // Exit if the image is already a thumbnail.
//       if (fileName.startsWith('thumb_')) {
//         return console.log('Already a Thumbnail.');
//       }
//       // [END stopConditions]
    
//       // [START thumbnailGeneration]
//       // Download file from bucket.
//       const bucket = admin.storage().bucket(fileBucket);
//       const tempFilePath = path.join(os.tmpdir(), fileName);
//       const metadata = {
//         contentType: contentType,
//       };
      
//       await bucket.file(filePath).download({destination: tempFilePath});
//       console.log('Image downloaded locally to', tempFilePath);
//       // Generate a thumbnail using ImageMagick.
//       await spawn('convert', [tempFilePath, '-thumbnail', '200x200>', tempFilePath]);
//       console.log('Thumbnail created at', tempFilePath);
//       // We add a 'thumb_' prefix to thumbnails file name. That's where we'll upload the thumbnail.
//       const thumbFileName = `thumb_${fileName}`;
//       const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
//       // Uploading the thumbnail.
//       await bucket.upload(tempFilePath, {
//         destination: thumbFilePath,
//         metadata: metadata,
//       });
//       // Once the thumbnail has been uploaded delete the local file to free up disk space.
//       return fs.unlinkSync(tempFilePath);
//       // [END thumbnailGeneration]
// });
// // [END generateThumbnail]