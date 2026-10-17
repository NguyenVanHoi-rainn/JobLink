import {
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';

import {
  cert,
  getApps,
  initializeApp,
} from 'firebase-admin/app';

import { getStorage } from 'firebase-admin/storage';

@Injectable()
export class FirebaseService {
  constructor() {
    if (getApps().length === 0) {
      const projectId = process.env.FIREBASE_PROJECT_ID;
      const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
      const privateKey = process.env.FIREBASE_PRIVATE_KEY;
      const storageBucket = process.env.FIREBASE_STORAGE_BUCKET;

      if (
        !projectId ||
        !clientEmail ||
        !privateKey ||
        !storageBucket
      ) {
        throw new Error(
          'Thiếu cấu hình Firebase trong file .env',
        );
      }

      initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
        storageBucket,
      });
    }
  }

  async uploadCv(
    file: Express.Multer.File,
    userId: string,
  ) {
    try {
      const bucket = getStorage().bucket();

      const storagePath =
        `cvs/${userId}/${Date.now()}-${file.originalname}`;

      const fileRef = bucket.file(storagePath);

      await fileRef.save(file.buffer, {
        metadata: {
          contentType: file.mimetype,
        },
      });

      await fileRef.makePublic();

      const fileUrl =
        `https://storage.googleapis.com/${bucket.name}/${storagePath}`;

      return {
        fileName: file.originalname,
        fileUrl,
      };
    } catch (error) {
      console.error(error);

      throw new InternalServerErrorException(
        'Không thể upload CV',
      );
    }
  }
}