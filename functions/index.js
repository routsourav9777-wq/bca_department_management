const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} =
    require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const messaging = admin.messaging();
const db = admin.firestore();

setGlobalOptions({
  region: "asia-south1",
  maxInstances: 10,
});


/**
 * Normalizes a semester value to a number from 1 to 6.
 *
 * @param {*} value Semester value.
 * @return {string|null} Normalized semester number.
 */
function normalizeSemester(value) {
  const raw = String(value || "")
      .trim()
      .toLowerCase();

  const match = raw.match(/[1-6]/);

  if (!match) {
    return null;
  }

  return match[0];
}


// ============================================================
// 1. NEW STUDENT REGISTRATION -> HOD
// ============================================================

exports.notifyHodNewStudentRegistrationV2 =
    onDocumentCreated(
        "students/{studentUid}",
        async (event) => {
          const snapshot = event.data;

          if (!snapshot) {
            logger.warn(
                "Student registration event has no data.",
            );
            return;
          }

          try {
            const studentData = snapshot.data();

            if (!studentData) {
              logger.warn(
                  "Student document contains no data.",
              );
              return;
            }

            const studentUid =
                String(event.params.studentUid);

            const name =
                String(
                    studentData.name ||
                    "New Student",
                ).trim();

            const email =
                String(
                    studentData.email ||
                    "",
                ).trim();

            const phone =
                String(
                    studentData.phone ||
                    "",
                ).trim();

            const rollNo =
                String(
                    studentData.rollNo ||
                    "Not provided",
                ).trim();

            const semester =
                String(
                    studentData.semester ||
                    "Not provided",
                ).trim();

            const status =
                String(
                    studentData.status ||
                    "",
                )
                    .trim()
                    .toLowerCase();

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

            if (status !== "pending") {
              logger.info(
                  "Student is not pending. " +
                  "Skipping notification.",
                  {
                    studentUid: studentUid,
                    status: status,
                  },
              );
              return;
            }

            const message = {
              topic: "hod",

              notification: {
                title: "New Student Registration",
                body:
                    `${name} has submitted a new registration. ` +
                    `Roll No: ${rollNo}`,
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

            logger.info(
                "Sending notification to HOD topic.",
                {
                  topic: "hod",
                  studentUid: studentUid,
                },
            );

            const messageId =
                await messaging.send(message);

            logger.info(
                "HOD notification sent successfully.",
                {
                  messageId: messageId,
                  studentUid: studentUid,
                },
            );
          } catch (error) {
            logger.error(
                "HOD registration notification failed.",
                {
                  error:
                      error.message ||
                      String(error),

                  stack:
                      error.stack ||
                      "",
                },
            );

            throw error;
          }
        },
    );


// ============================================================
// 2. HOD -> STUDENTS / FACULTY
// ============================================================

exports.sendDepartmentPushNotificationV2 =
    onDocumentCreated(
        "notifications/{notificationId}",
        async (event) => {
          const snapshot = event.data;

          if (!snapshot) {
            logger.warn(
                "Notification event has no data.",
            );
            return;
          }

          const notificationId =
              String(event.params.notificationId);

          try {
            // ==================================================
            // READ NOTIFICATION
            // ==================================================

            const notificationData =
                snapshot.data();

            if (!notificationData) {
              logger.warn(
                  "Notification document contains no data.",
                  {
                    notificationId: notificationId,
                  },
              );
              return;
            }

            // ==================================================
            // TYPE
            // ==================================================

            const type =
                String(
                    notificationData.type ||
                    "",
                )
                    .trim()
                    .toLowerCase();

            if (type !== "push") {
              logger.info(
                  "Skipping non-push notification.",
                  {
                    notificationId: notificationId,
                    type: type,
                  },
              );
              return;
            }

            // ==================================================
            // STATUS
            // ==================================================

            const status =
                String(
                    notificationData.status ||
                    "",
                )
                    .trim()
                    .toLowerCase();

            if (status !== "pending") {
              logger.info(
                  "Skipping notification because " +
                  "it is not pending.",
                  {
                    notificationId: notificationId,
                    status: status,
                  },
              );
              return;
            }

            // ==================================================
            // TITLE
            // ==================================================

            const title =
                String(
                    notificationData.title ||
                    "BCA Department",
                ).trim();

            // ==================================================
            // BODY
            // ==================================================

            const body =
                String(
                    notificationData.body ||
                    "",
                ).trim();

            // ==================================================
            // TARGET
            // ==================================================

            const target =
                String(
                    notificationData.target ||
                    "all",
                )
                    .trim()
                    .toLowerCase();

            // ==================================================
            // VALIDATION
            // ==================================================

            if (!title) {
              throw new Error(
                  "Notification title is empty.",
              );
            }

            if (!body) {
              throw new Error(
                  "Notification body is empty.",
              );
            }

            // ==================================================
            // LOG
            // ==================================================

            logger.info(
                "Department notification received.",
                {
                  notificationId: notificationId,
                  title: title,
                  target: target,
                },
            );

            // ==================================================
            // STATUS -> SENDING
            // ==================================================

            await snapshot.ref.update({
              status: "sending",

              sendingStartedAt:
                  admin.firestore.FieldValue
                      .serverTimestamp(),
            });

            // ==================================================
            // COMMON DATA
            // ==================================================

            const data = {
              type: "department_notification",

              route: "notifications",

              notificationId: notificationId,

              title: title,

              body: body,

              target: target,
            };

            // ==================================================
            // ANDROID SETTINGS
            // ==================================================

            const android = {
              priority: "high",

              notification: {
                channelId: "bca_department_high",

                sound: "default",

                clickAction:
                    "FLUTTER_NOTIFICATION_CLICK",
              },
            };

            // ==================================================
            // RESULTS
            // ==================================================

            const sendResults = [];

            let totalSent = 0;

            let totalFailed = 0;


            // ==================================================
            // TARGET: ALL
            // ==================================================

            if (target === "all") {
              const topics = [
                "all_students",
                "all_staff",
              ];

              logger.info(
                  "Sending notification to all.",
                  {
                    notificationId: notificationId,
                    topics: topics,
                  },
              );

              for (const topic of topics) {
                try {
                  const message = {
                    topic: topic,

                    notification: {
                      title: title,
                      body: body,
                    },

                    data: data,

                    android: android,
                  };

                  const messageId =
                      await messaging.send(message);

                  totalSent++;

                  sendResults.push({
                    method: "topic",
                    topic: topic,
                    messageId: messageId,
                    status: "sent",
                  });

                  logger.info(
                      "Topic notification sent.",
                      {
                        notificationId:
                            notificationId,

                        topic: topic,

                        messageId:
                            messageId,
                      },
                  );
                } catch (error) {
                  totalFailed++;

                  sendResults.push({
                    method: "topic",
                    topic: topic,
                    status: "failed",
                    error:
                        error.message ||
                        String(error),
                  });

                  logger.error(
                      "Topic notification failed.",
                      {
                        notificationId:
                            notificationId,

                        topic: topic,

                        error:
                            error.message ||
                            String(error),
                      },
                  );
                }
              }
            } else if (target === "faculty") {
              // ==================================================
              // TARGET: FACULTY
              // ==================================================

              const topic = "faculty";

              try {
                const message = {
                  topic: topic,

                  notification: {
                    title: title,
                    body: body,
                  },

                  data: data,

                  android: android,
                };

                const messageId =
                    await messaging.send(message);

                totalSent++;

                sendResults.push({
                  method: "topic",
                  topic: topic,
                  messageId: messageId,
                  status: "sent",
                });

                logger.info(
                    "Faculty notification sent.",
                    {
                      notificationId:
                          notificationId,

                      topic: topic,

                      messageId:
                          messageId,
                    },
                );
              } catch (error) {
                totalFailed++;

                sendResults.push({
                  method: "topic",
                  topic: topic,
                  status: "failed",
                  error:
                      error.message ||
                      String(error),
                });

                logger.error(
                    "Faculty notification failed.",
                    {
                      notificationId:
                          notificationId,

                      topic: topic,

                      error:
                          error.message ||
                          String(error),
                    },
                );
              }
            } else if (
              target === "semester_1" ||
              target === "semester_2" ||
              target === "semester_3" ||
              target === "semester_4" ||
              target === "semester_5" ||
              target === "semester_6"
            ) {
              // ==================================================
              // TARGET: SEMESTER 1-6
              // ==================================================

              const requestedSemester =
                  target.replace(
                      "semester_",
                      "",
                  );

              logger.info(
                  "Semester notification requested.",
                  {
                    notificationId:
                        notificationId,

                    target: target,

                    semester:
                        requestedSemester,
                  },
              );

              // =================================================
              // GET APPROVED STUDENTS
              // =================================================

              const studentsSnapshot =
                  await db
                      .collection("students")
                      .where(
                          "status",
                          "==",
                          "approved",
                      )
                      .get();

              logger.info(
                  "Approved students fetched.",
                  {
                    notificationId:
                        notificationId,

                    totalStudents:
                        studentsSnapshot.size,
                  },
              );

              // =================================================
              // FIND TARGET SEMESTER
              // =================================================

              const studentUids = [];

              for (
                const studentDoc
                of studentsSnapshot.docs
              ) {
                const studentData =
                    studentDoc.data();

                const studentSemester =
                    normalizeSemester(
                        studentData.semester,
                    );

                logger.info(
                    "Checking student semester.",
                    {
                      uid:
                          studentDoc.id,

                      semester:
                          studentData.semester,

                      normalizedSemester:
                          studentSemester,
                    },
                );

                if (
                  studentSemester ===
                  requestedSemester
                ) {
                  studentUids.push(
                      studentDoc.id,
                  );
                }
              }

              logger.info(
                  "Target semester students found.",
                  {
                    notificationId:
                        notificationId,

                    semester:
                        requestedSemester,

                    studentCount:
                        studentUids.length,
                  },
              );

              // =================================================
              // NO STUDENTS
              // =================================================

              if (studentUids.length === 0) {
                logger.warn(
                    "No approved students found " +
                    "for selected semester.",
                    {
                      notificationId:
                          notificationId,

                      semester:
                          requestedSemester,
                    },
                );

                sendResults.push({
                  method: "direct_token",

                  target: target,

                  semester:
                      requestedSemester,

                  status: "no_students",
                });
              }

              // =================================================
              // SEND TO EACH STUDENT TOKEN
              // =================================================

              for (
                const studentUid
                of studentUids
              ) {
                try {
                  const tokenDoc =
                      await db
                          .collection(
                              "fcm_tokens",
                          )
                          .doc(
                              studentUid,
                          )
                          .get();

                  // =============================================
                  // NO TOKEN DOCUMENT
                  // =============================================

                  if (!tokenDoc.exists) {
                    logger.warn(
                        "No FCM token found for student.",
                        {
                          studentUid:
                              studentUid,

                          semester:
                              requestedSemester,
                        },
                    );

                    sendResults.push({
                      method:
                          "direct_token",

                      studentUid:
                          studentUid,

                      semester:
                          requestedSemester,

                      status:
                          "no_token",
                    });

                    continue;
                  }

                  // =============================================
                  // TOKEN DATA
                  // =============================================

                  const tokenData =
                      tokenDoc.data();

                  const token =
                      String(
                          (tokenData &&
                              tokenData.token) ||
                          "",
                      ).trim();

                  // =============================================
                  // EMPTY TOKEN
                  // =============================================

                  if (!token) {
                    logger.warn(
                        "FCM token is empty.",
                        {
                          studentUid:
                              studentUid,
                        },
                    );

                    sendResults.push({
                      method:
                          "direct_token",

                      studentUid:
                          studentUid,

                      semester:
                          requestedSemester,

                      status:
                          "empty_token",
                    });

                    continue;
                  }

                  // =============================================
                  // DIRECT FCM MESSAGE
                  // =============================================

                  const message = {
                    token: token,

                    notification: {
                      title: title,
                      body: body,
                    },

                    data: data,

                    android: android,
                  };

                  // =============================================
                  // SEND
                  // =============================================

                  const messageId =
                      await messaging.send(
                          message,
                      );

                  totalSent++;

                  sendResults.push({
                    method:
                        "direct_token",

                    studentUid:
                        studentUid,

                    semester:
                        requestedSemester,

                    messageId:
                        messageId,

                    status:
                        "sent",
                  });

                  logger.info(
                      "Semester notification sent directly.",
                      {
                        notificationId:
                            notificationId,

                        studentUid:
                            studentUid,

                        semester:
                            requestedSemester,

                        messageId:
                            messageId,
                      },
                  );
                } catch (error) {
                  totalFailed++;

                  sendResults.push({
                    method:
                        "direct_token",

                    studentUid:
                        studentUid,

                    semester:
                        requestedSemester,

                    status:
                        "failed",

                    error:
                        error.message ||
                        String(error),
                  });

                  logger.error(
                      "Failed to send semester notification.",
                      {
                        notificationId:
                            notificationId,

                        studentUid:
                            studentUid,

                        semester:
                            requestedSemester,

                        error:
                            error.message ||
                            String(error),
                      },
                  );
                }
              }
            } else {
              // ==================================================
              // INVALID TARGET
              // ==================================================

              throw new Error(
                  "Invalid notification target: " +
                  target,
              );
            }

            // ==================================================
            // FINAL STATUS
            // ==================================================

            let finalStatus = "sent";

            if (
              totalSent === 0 &&
              totalFailed > 0
            ) {
              finalStatus = "failed";
            }

            // ==================================================
            // SAVE RESULT
            // ==================================================

            await snapshot.ref.update({
              status: finalStatus,

              sendResults: sendResults,

              totalSent: totalSent,

              totalFailed: totalFailed,

              sentAt:
                  admin.firestore.FieldValue
                      .serverTimestamp(),
            });

            // ==================================================
            // FINAL LOG
            // ==================================================

            logger.info(
                "Department notification completed.",
                {
                  notificationId:
                      notificationId,

                  target: target,

                  totalSent:
                      totalSent,

                  totalFailed:
                      totalFailed,

                  status:
                      finalStatus,
                },
            );
          } catch (error) {
            // ==================================================
            // ERROR LOG
            // ==================================================

            logger.error(
                "Department notification failed.",
                {
                  notificationId:
                      notificationId,

                  error:
                      error.message ||
                      String(error),

                  stack:
                      error.stack ||
                      "",
                },
            );

            // ==================================================
            // SAVE ERROR
            // ==================================================

            try {
              await snapshot.ref.update({
                status: "failed",

                error:
                    error.message ||
                    String(error),

                failedAt:
                    admin.firestore.FieldValue
                        .serverTimestamp(),
              });
            } catch (updateError) {
              logger.error(
                  "Could not save notification error.",
                  {
                    notificationId:
                        notificationId,

                    error:
                        updateError.message ||
                        String(updateError),
                  },
              );
            }

            throw error;
          }
        },
    );
