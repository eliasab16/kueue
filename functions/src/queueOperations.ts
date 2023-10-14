import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { user } from 'firebase-functions/v1/auth';

const {logger} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");


const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

const firestore = admin.firestore();

export const changeStudentQueueStatus = onRequest(async (req: any, res: any) => {
    try {
        const requestData = req.query;

        const documentId = requestData.documentId;
        const userRef = requestData.userRef;
        const newStatus: boolean = requestData.newStatus;

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

            if (studentObject.userRef == userRef) {
                studentObject.queueStatus = newStatus;
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

// TODO: make sure race conditions are handled properly
export const deleteStudentFromQueue = onRequest(async (req: any, res: any) => {
    try {
        const requestData = req.query;

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

            if (studentObject.userRef == userRef) {
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
