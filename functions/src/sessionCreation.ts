import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v1/https";

const firestore = admin.firestore();

const sessionCodeRef = firestore.collection('meatdata').doc('CQILBppMsJ1myTSKH44C');

/**
 * Creates a unique code by incrementing a global variable in firestore
 * @returns a promise for the unique session code to be used for joining the new session
 */
async function getUniqueSessionCode(): Promise<number> {
    try {
        // must be transactional to avoid race conditions, as session codes should be unique
        const updatedCode = await firestore.runTransaction(async (t) => {
            const doc = await t.get(sessionCodeRef);
            const newCode = doc.data()!.last_session_code + 1;

            t.update(sessionCodeRef, {last_session_code: newCode});
            return newCode;
        });

        return updatedCode;
    } catch (e) {
        console.error(`Unique code transaction failed ${e}`);
        throw e;
    }
}

export const createNewSession = onRequest(async (req: any, res: any) => {
    try {
        const requestData = req.body.data;

        const code = await getUniqueSessionCode();

        const result = await firestore.collection('sessions').add({
            course_name: requestData.courseName,
            hosts: requestData.hosts,
            active_status: requestData.activeStatus,
            topic: requestData.topic,
            start_time: requestData.startTime,
            joining_code: String(code),
        });

        console.info(`Added new session with ID ${code}`)
        res = result;
    } catch (e) {
        console.error(`Error while creating a new session ${e}`);
    }
})
