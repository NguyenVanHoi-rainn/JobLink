import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

import { CreatePrivateConversationDto } from './dto/create-private-conversation.dto.js';
import { SendMessageDto } from './dto/send-message.dto.js';
import { CreateSelectedGroupDto } from './dto/create-selected-group.dto.js';
import { AddSelectedGroupMembersDto } from './dto/add-selected-group-members.dto.js';
import { NotificationsService } from '../notifications/notifications.service.js';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

    private async getEmployer(
    userId: string,
    ) {
    const employer =
        await this.prisma.employerProfile.findUnique({
        where: {
            userId,
        },
        });

    if (!employer) {
        throw new NotFoundException(
        'Không tìm thấy hồ sơ Employer',
        );
    }

    return employer;
    }  

    private async getEmployerJob(
    userId: string,
    jobId: string,
    ) {
    const employer =
        await this.getEmployer(userId);

    const job =
        await this.prisma.job.findFirst({
        where: {
            id: jobId,
            employerId: employer.id,
        },
        });

    if (!job) {
        throw new NotFoundException(
        'Không tìm thấy tin tuyển dụng',
        );
    }

    return {
        employer,
        job,
    };
    }

    private async safeNotify(data: {
    userId: string;
    title: string;
    content: string;
    type: string;
    referenceType?: string;
    referenceId?: string;
    }) {
    try {
        await this.notificationsService.create(data);
    } catch (error) {
        console.error(
        'Chat notification failed:',
        error,
        );
    }
    }

  async assertMember(
    userId: string,
    conversationId: string,
  ) {
    const member =
      await this.prisma.conversationMember.findFirst({
        where: {
          conversationId,
          userId,
        },
      });

    if (!member) {
      throw new ForbiddenException(
        'Bạn không thuộc cuộc trò chuyện này',
      );
    }

    return member;
  }

  async getConversationIdsForUser(
    userId: string,
  ) {
    const memberships =
      await this.prisma.conversationMember.findMany({
        where: {
          userId,
        },

        select: {
          conversationId: true,
        },
      });

    return memberships.map(
      (item) => item.conversationId,
    );
  }

  private async checkRecruitmentRelationship(
    userId: string,
    targetUserId: string,
  ) {
    const user =
      await this.prisma.user.findUnique({
        where: { id: userId },
      });

    const target =
      await this.prisma.user.findUnique({
        where: { id: targetUserId },
      });

    if (!user || !target) {
      throw new NotFoundException(
        'Không tìm thấy người dùng',
      );
    }

    if (
      user.status !== 'ACTIVE' ||
      target.status !== 'ACTIVE'
    ) {
      throw new BadRequestException(
        'Tài khoản không hoạt động',
      );
    }

    const validPair =
      (user.role === 'WORKER' &&
        target.role === 'EMPLOYER') ||
      (user.role === 'EMPLOYER' &&
        target.role === 'WORKER');

    if (!validPair) {
      throw new BadRequestException(
        'Chat riêng chỉ áp dụng giữa Worker và Employer',
      );
    }

    let workerUserId: string;
    let employerUserId: string;

    if (user.role === 'WORKER') {
      workerUserId = userId;
      employerUserId = targetUserId;
    } else {
      workerUserId = targetUserId;
      employerUserId = userId;
    }

    const worker =
      await this.prisma.workerProfile.findUnique({
        where: {
          userId: workerUserId,
        },
      });

    const employer =
      await this.prisma.employerProfile.findUnique({
        where: {
          userId: employerUserId,
        },
      });

    if (!worker || !employer) {
      throw new NotFoundException(
        'Không tìm thấy hồ sơ Worker hoặc Employer',
      );
    }

    const employerJobs =
      await this.prisma.job.findMany({
        where: {
          employerId: employer.id,
        },

        select: {
          id: true,
        },
      });

    const jobIds =
      employerJobs.map(
        (job) => job.id,
      );

    if (jobIds.length === 0) {
      throw new ForbiddenException(
        'Worker và Employer chưa có quan hệ tuyển dụng',
      );
    }

    const application =
      await this.prisma.application.findFirst({
        where: {
          workerId: worker.id,

          jobId: {
            in: jobIds,
          },
        },
      });

    if (!application) {
      throw new ForbiddenException(
        'Worker cần ứng tuyển công việc của Employer trước khi chat',
      );
    }
  }

  async createPrivateConversation(
    userId: string,
    dto: CreatePrivateConversationDto,
  ) {
    if (userId === dto.targetUserId) {
      throw new BadRequestException(
        'Không thể tự chat với chính mình',
      );
    }

    await this.checkRecruitmentRelationship(
      userId,
      dto.targetUserId,
    );

    // Tìm conversation mà cả hai cùng là member.
    const myMemberships =
      await this.prisma.conversationMember.findMany({
        where: {
          userId,
        },

        select: {
          conversationId: true,
        },
      });

    const myConversationIds =
      myMemberships.map(
        (item) => item.conversationId,
      );

    if (myConversationIds.length > 0) {
      const targetMemberships =
        await this.prisma.conversationMember.findMany({
          where: {
            userId: dto.targetUserId,

            conversationId: {
              in: myConversationIds,
            },
          },

          select: {
            conversationId: true,
          },
        });

      const commonIds =
        targetMemberships.map(
          (item) => item.conversationId,
        );

      if (commonIds.length > 0) {
        const existing =
          await this.prisma.conversation.findFirst({
            where: {
              id: {
                in: commonIds,
              },

              type: 'PRIVATE',
            },
          });

        if (existing) {
          return existing;
        }
      }
    }

    return this.prisma.$transaction(
      async (tx) => {
        const conversation =
          await tx.conversation.create({
            data: {
              createdBy: userId,
              type: 'PRIVATE',
            },
          });

        await tx.conversationMember.createMany({
          data: [
            {
              conversationId:
                conversation.id,

              userId,

              memberRole:
                'MEMBER',
            },

            {
              conversationId:
                conversation.id,

              userId:
                dto.targetUserId,

              memberRole:
                'MEMBER',
            },
          ],
        });

        return conversation;
      },
    );
  }

  async getMyConversations(
    userId: string,
  ) {
    const ids =
      await this.getConversationIdsForUser(
        userId,
      );

    if (ids.length === 0) {
      return [];
    }

    const conversations =
      await this.prisma.conversation.findMany({
        where: {
          id: {
            in: ids,
          },
        },

        orderBy: {
          createdAt: 'desc',
        },
      });

    return Promise.all(
      conversations.map(
        async (conversation) => {
          const members =
            await this.prisma.conversationMember.findMany({
              where: {
                conversationId:
                  conversation.id,
              },

              select: {
                userId: true,
                memberRole: true,
              },
            });

          const lastMessage =
            await this.prisma.message.findFirst({
              where: {
                conversationId:
                  conversation.id,
              },

              orderBy: {
                sentAt: 'desc',
              },
            });

          return {
            ...conversation,
            members,
            lastMessage,
          };
        },
      ),
    );
  }

  async getMessages(
    userId: string,
    conversationId: string,
    page = 1,
    limit = 50,
  ) {
    await this.assertMember(
      userId,
      conversationId,
    );

    const skip =
      (page - 1) * limit;

    const messages =
      await this.prisma.message.findMany({
        where: {
          conversationId,
        },

        orderBy: {
          sentAt: 'desc',
        },

        skip,
        take: limit,
      });

    const total =
      await this.prisma.message.count({
        where: {
          conversationId,
        },
      });

    return {
      page,
      limit,
      total,
      totalPages:
        Math.ceil(total / limit),

      items:
        messages.reverse(),
    };
  }

  async sendMessage(
    userId: string,
    conversationId: string,
    dto: SendMessageDto,
  ) {
    const membership =
      await this.assertMember(
        userId,
        conversationId,
      );

    const conversation =
      await this.prisma.conversation.findUnique({
        where: {
          id: conversationId,
        },
      });

    if (!conversation) {
      throw new NotFoundException(
        'Không tìm thấy cuộc trò chuyện',
      );
    }

    // Applicant Group: Worker chỉ đọc.
    if (
      conversation.type === 'APPLICANT_GROUP' &&
      membership.memberRole !== 'OWNER'
    ) {
      throw new ForbiddenException(
        'Worker chỉ có quyền đọc trong Applicant Group',
      );
    }

    const messageType =
      dto.messageType ?? 'TEXT';

    if (
      messageType === 'TEXT' &&
      !dto.content?.trim()
    ) {
      throw new BadRequestException(
        'Tin nhắn không được để trống',
      );
    }

    if (
      (messageType === 'IMAGE' ||
        messageType === 'FILE') &&
      !dto.fileUrl
    ) {
      throw new BadRequestException(
        'Tin nhắn IMAGE/FILE cần có fileUrl',
      );
    }

    if (dto.replyToId) {
      const replyMessage =
        await this.prisma.message.findFirst({
          where: {
            id: dto.replyToId,
            conversationId,
          },
        });

      if (!replyMessage) {
        throw new NotFoundException(
          'Tin nhắn được reply không tồn tại',
        );
      }
    }

    const message =
    await this.prisma.message.create({
        data: {
        conversationId,
        senderId: userId,

        content:
            dto.content?.trim() ||
            null,

        messageType:
            dto.messageType ??
            'TEXT',

        fileUrl:
            dto.fileUrl ??
            null,

        replyToId:
            dto.replyToId ??
            null,
        },
    });

    const otherMembers =
    await this.prisma.conversationMember.findMany({
        where: {
        conversationId,

        userId: {
            not: userId,
        },
        },

        select: {
        userId: true,
        },
    });

    let title =
    'Bạn có tin nhắn mới';

    if (
    conversation.type ===
    'APPLICANT_GROUP'
    ) {
    title =
        'Thông báo từ nhà tuyển dụng';
    } else if (
    conversation.type ===
    'SELECTED_GROUP'
    ) {
    title =
        'Tin nhắn mới trong nhóm';
    }

    await Promise.all(
    otherMembers.map(
        (member) =>
        this.safeNotify({
            userId:
            member.userId,

            title,

            content:
            message.messageType ===
            'TEXT'
                ? (
                    message.content ||
                    'Bạn có tin nhắn mới'
                )
                : message.messageType ===
                    'IMAGE'
                ? 'Bạn nhận được một hình ảnh.'
                : 'Bạn nhận được một file.',

            type:
            'CHAT_MESSAGE',

            referenceType:
            'CONVERSATION',

            referenceId:
            conversationId,
        }),
    ),
    );

    return message;

  }

    async getApplicantGroup(
    userId: string,
    jobId: string,
    ) {
    const group =
        await this.prisma.conversation.findFirst({
        where: {
            jobId,
            type: 'APPLICANT_GROUP',

            members: {
            some: {
                userId,
            },
            },
        },

        include: {
            members: true,
        },
        });

    if (!group) {
        throw new NotFoundException(
        'Không tìm thấy Applicant Group hoặc bạn không thuộc nhóm',
        );
    }

    return group;
    }

    async getJobGroups(
    userId: string,
    jobId: string,
    ) {
    await this.getEmployerJob(
        userId,
        jobId,
    );

    return this.prisma.conversation.findMany({
        where: {
        jobId,

        type: {
            in: [
            'APPLICANT_GROUP',
            'SELECTED_GROUP',
            ],
        },
        },

        include: {
        members: true,

        _count: {
            select: {
            messages: true,
            },
        },
        },

        orderBy: {
        createdAt: 'asc',
        },
    });
    }

    async createSelectedGroup(
    userId: string,
    jobId: string,
    dto: CreateSelectedGroupDto,
    ) {
    const {
        job,
    } = await this.getEmployerJob(
        userId,
        jobId,
    );

    const uniqueIds = [
        ...new Set(
        dto.memberUserIds,
        ),
    ];

    if (
        uniqueIds.includes(
        userId,
        )
    ) {
        throw new BadRequestException(
        'Không cần thêm Employer vào memberUserIds',
        );
    }

    // Kiểm tra tất cả Worker có thực sự
    // ứng tuyển Job này hay không.
    const applications =
        await this.prisma.application.findMany({
        where: {
            jobId,

            status: {
            notIn: [
                'WITHDRAWN',
                'REJECTED',
            ],
            },

            worker: {
            userId: {
                in: uniqueIds,
            },
            },
        },

        include: {
            worker: true,
        },
        });

    const validUserIds =
        applications.map(
        (application) =>
            application.worker.userId,
        );

    if (
        validUserIds.length !==
        uniqueIds.length
    ) {
        throw new BadRequestException(
        'Có Worker không thuộc danh sách ứng viên hợp lệ của Job',
        );
    }

    return this.prisma.$transaction(
        async (tx) => {
        const group =
            await tx.conversation.create({
            data: {
                jobId,

                createdBy:
                userId,

                type:
                'SELECTED_GROUP',

                name:
                dto.name,
            },
            });

        // Employer = OWNER
        await tx.conversationMember.create({
            data: {
            conversationId:
                group.id,

            userId,

            memberRole:
                'OWNER',
            },
        });

        // Worker = MEMBER
        await tx.conversationMember.createMany({
            data:
            uniqueIds.map(
                (workerUserId) => ({
                conversationId:
                    group.id,

                userId:
                    workerUserId,

                memberRole:
                    'MEMBER',
                }),
            ),

            skipDuplicates: true,
        });

        return tx.conversation.findUnique({
            where: {
            id: group.id,
            },

            include: {
            members: true,
            },
        });
        },
    );
    }

    async addSelectedGroupMembers(
    userId: string,
    groupId: string,
    dto: AddSelectedGroupMembersDto,
    ) {
    const group =
        await this.prisma.conversation.findFirst({
        where: {
            id: groupId,

            type:
            'SELECTED_GROUP',

            createdBy:
            userId,
        },
        });

    if (!group) {
        throw new NotFoundException(
        'Không tìm thấy Selected Group hoặc bạn không có quyền quản lý',
        );
    }

    if (!group.jobId) {
        throw new BadRequestException(
        'Selected Group không gắn với Job',
        );
    }

    const uniqueIds = [
        ...new Set(
        dto.memberUserIds,
        ),
    ];

    const applications =
        await this.prisma.application.findMany({
        where: {
            jobId:
            group.jobId,

            status: {
            notIn: [
                'WITHDRAWN',
                'REJECTED',
            ],
            },

            worker: {
            userId: {
                in: uniqueIds,
            },
            },
        },

        include: {
            worker: true,
        },
        });

    const validUserIds =
        applications.map(
        (application) =>
            application.worker.userId,
        );

    if (
        validUserIds.length !==
        uniqueIds.length
    ) {
        throw new BadRequestException(
        'Có Worker không phải ứng viên hợp lệ của Job',
        );
    }

    await this.prisma.conversationMember.createMany({
        data:
        uniqueIds.map(
            (workerUserId) => ({
            conversationId:
                groupId,

            userId:
                workerUserId,

            memberRole:
                'MEMBER',
            }),
        ),

        skipDuplicates: true,
    });

    return this.prisma.conversation.findUnique({
        where: {
        id: groupId,
        },

        include: {
        members: true,
        },
    });
    }    

    async removeSelectedGroupMember(
    employerUserId: string,
    groupId: string,
    memberUserId: string,
    ) {
    const group =
        await this.prisma.conversation.findFirst({
        where: {
            id: groupId,

            type:
            'SELECTED_GROUP',

            createdBy:
            employerUserId,
        },
        });

    if (!group) {
        throw new NotFoundException(
        'Không tìm thấy Selected Group hoặc bạn không có quyền quản lý',
        );
    }

    if (
        employerUserId ===
        memberUserId
    ) {
        throw new BadRequestException(
        'Không thể xóa OWNER khỏi Selected Group',
        );
    }

    const member =
        await this.prisma.conversationMember.findFirst({
        where: {
            conversationId:
            groupId,

            userId:
            memberUserId,
        },
        });

    if (!member) {
        throw new NotFoundException(
        'Worker không thuộc Selected Group',
        );
    }

    await this.prisma.conversationMember.deleteMany({
        where: {
        conversationId:
            groupId,

        userId:
            memberUserId,
        },
    });

    return {
        message:
        'Xóa thành viên khỏi Selected Group thành công',
    };
    }    

}