import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'fs';
import * as path from 'path';

@Injectable()
export class FilesService {
  private readonly uploadDir: string;

  constructor(private readonly config: ConfigService) {
    this.uploadDir = this.config.get<string>('UPLOAD_DIR') ?? 'uploads';
  }

  async saveFile(file: Express.Multer.File): Promise<string> {
    await fs.mkdir(this.uploadDir, { recursive: true });
    const safeOriginalName = path
      .basename(file.originalname)
      .replace(/[^a-zA-Z0-9._-]/g, '_');
    const fileName = `${Date.now()}-${safeOriginalName}`;
    const filePath = path.join(this.uploadDir, fileName);
    await fs.writeFile(filePath, file.buffer);

    const publicBaseUrl =
      this.config.get<string>('FILES_PUBLIC_BASE_URL') ??
      this.config.get<string>('BASE_URL') ??
      'http://localhost:3000';

    return `${publicBaseUrl.replace(/\/$/, '')}/uploads/${fileName}`;
  }
}
