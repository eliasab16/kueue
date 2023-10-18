import * as admin from 'firebase-admin';

const {onRequest} = require("firebase-functions/v2/https");

const firestore = admin.firestore();

export const changeStudentQueueStatus = onRequest(async (req: any, res: any) => {
    try {
        const requestData = req.body.data;
        const documentId = requestData.documentId;
        const userRef = requestData.userRef;
        const newStatus = requestData.newStatus;

        const docRef = firestore.collection('sessions').doc(documentId);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).send(`Document with id ${documentId} not found.`);
            return;
        }

        // replace the entire array after we modify the specific student object
        // TODO: make sure race conditions are handled properly
        const queueArray: [any] = doc.data()?.queue || [];

        for (let index = 0; index < queueArray.length; index++) {
            const studentObject = queueArray[index];
            const refPath = studentObject.user_ref._path.segments.join('/');

            if (refPath == userRef) {
                studentObject.queue_status = newStatus;
                break;
            }
        }

        await docRef.update({ queue: queueArray });
        res.status(200).send('Queue array updated successfully');
    } catch (error) {
        console.error('Error while updating queue array:', req.body);
        res.status(500).send('Internal Server Error');
    }
})

// TODO: make sure race conditions are handled properly
export const deleteStudentFromQueue = onRequest(async (req: any, res: any) => {
    try {
        const requestData = req.body.data;

        const documentId = requestData.documentId;
        const userRef = requestData.userRef;

        const docRef = firestore.collection('sessions').doc(documentId);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).send(`Document with id ${documentId} not found.`);
            return;
        }

        // TODO: make sure race conditions are handled properly
        const queueArray: [any] = doc.data()?.queue || [];

        for (let index = 0; index < queueArray.length; index++) {
            const studentObject = queueArray[index];
            const refPath = studentObject.user_ref._path.segments.join('/');

            if (refPath == userRef) {
                queueArray.splice(index, 1);
                break;
            }
        }

        await docRef.update({ queue: queueArray });
        res.status(200).send('Queue array updated successfully');
    } catch (error) {
        console.error('Error updating queue array:', error);
        res.status(500).send('Internal Server Error');
    }
})
