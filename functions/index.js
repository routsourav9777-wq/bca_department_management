const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

// Global settings for all Cloud Functions
setGlobalOptions({
  maxInstances: 10,
});

/**
 * Send notification to HOD when a new student registration
 * is created with status "pending".
 *
 * Firestore path:
 * students/{studentUid}
 */
exports.notifyHodNewStudentRegistrationV2 =
    onDocumentCreated(
        "students/{studentUid}",
        async (event) => {
          try {
            // Get newly created Firestore document
            const snapshot = event.data;

            if (!snapshot) {
              logger.warn(
                  "Student registration event has no data.",
              );
              return;
            }

            // Get student data
            const studentData = snapshot.data();

            if (!studentData) {
              logger.warn(
                  "Student document contains no data.",
              );
              return;
            }

            // Read student fields safely
            const name = studentData.name ?
              String(studentData.name).trim() :
              "New Student";

            const email = studentData.email ?
              String(studentData.email).trim() :
              "";

            const phone = studentData.phone ?
              String(studentData.phone).trim() :
              "";

            const rollNo = studentData.rollNo ?
              String(studentData.rollNo).trim() :
              "Not provided";

            const semester = studentData.semester ?
              String(studentData.semester).trim() :
              "Not provided";

            const status = studentData.status ?
              String(studentData.status).trim().toLowerCase() :
              "";

            // Get UID from Firestore path
            const studentUid = event.params.studentUid;

            logger.info(
                "New student registration detected.",
                {
                  studentUid: studentUid,
                  name: name,
                  email: email,
                  rollNo: rollNo,
                  semester: semester,
                  status: status,
                },
            );

            // Only notify HOD for pending registrations
            if (status !== "pending") {
              logger.info(
                  "Student is not pending. Notification skipped.",
                  {
                    studentUid: studentUid,
                    status: status,
                  },
              );

              return;
            }

            // Notification title
            const notificationTitle =
                "New Student Registration";

            // Notification body
            const notificationBody =
                name +
                " has submitted a new registration. " +
                "Roll No: " +
                rollNo;

            // FCM message
            const message = {
              topic: "hod",

              notification: {
                title: notificationTitle,
                body: notificationBody,
              },

              data: {
                type: "student_registration",
                route: "pending_students",
                studentUid: studentUid,
                name: name,
                email: email,
                phone: phone,
                rollNo: rollNo,
                semester: semester,
                status: status,
              },

              android: {
                priority: "high",

                notification: {
                  channelId: "bca_department_high",
                  sound: "default",
                },
              },
            };

            // Send notification to HOD topic
            const response =
                await getMessaging().send(message);

            logger.info(
                "HOD notification sent successfully.",
                {
                  messageId: response,
                  studentUid: studentUid,
                  studentName: name,
                  rollNo: rollNo,
                  semester: semester,
                },
            );
          } catch (error) {
            logger.error(
                "Error sending HOD registration notification.",
                error,
            );

            throw error;
          }
        },
    );
