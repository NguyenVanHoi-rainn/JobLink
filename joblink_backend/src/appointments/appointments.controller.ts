import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';

import { AppointmentsService } from './appointments.service.js';

import { CreateWorkAppointmentDto } from './dto/create-work-appointment.dto.js';
import { UpdateWorkAppointmentDto } from './dto/update-work-appointment.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';

import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import { Roles } from '../auth/decorators/roles.decorator.js';

@Controller()
@UseGuards(
  JwtAuthGuard,
  RolesGuard,
)
export class AppointmentsController {
  constructor(
    private readonly appointmentsService:
      AppointmentsService,
  ) {}

  @Post(
    'employers/me/applications/:applicationId/appointment',
  )
  @Roles('EMPLOYER')
  createAppointment(
    @CurrentUser()
    user: any,

    @Param(
      'applicationId',
      ParseUUIDPipe,
    )
    applicationId: string,

    @Body()
    dto: CreateWorkAppointmentDto,
  ) {
    return this.appointmentsService.createAppointment(
      user.sub,
      applicationId,
      dto,
    );
  }

  @Get(
    'employers/me/appointments',
  )
  @Roles('EMPLOYER')
  getEmployerAppointments(
    @CurrentUser()
    user: any,
  ) {
    return this.appointmentsService.getEmployerAppointments(
      user.sub,
    );
  }

  @Patch(
    'employers/me/appointments/:id',
  )
  @Roles('EMPLOYER')
  updateAppointment(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,

    @Body()
    dto: UpdateWorkAppointmentDto,
  ) {
    return this.appointmentsService.updateAppointment(
      user.sub,
      id,
      dto,
    );
  }

  @Patch(
    'employers/me/appointments/:id/cancel',
  )
  @Roles('EMPLOYER')
  cancelAppointment(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.appointmentsService.cancelAppointment(
      user.sub,
      id,
    );
  }

  @Get(
    'workers/me/appointments',
  )
  @Roles('WORKER')
  getWorkerAppointments(
    @CurrentUser()
    user: any,
  ) {
    return this.appointmentsService.getWorkerAppointments(
      user.sub,
    );
  }

  @Patch(
    'workers/me/appointments/:id/confirm',
  )
  @Roles('WORKER')
  confirmAppointment(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.appointmentsService.confirmAppointment(
      user.sub,
      id,
    );
  }

  @Patch(
    'workers/me/appointments/:id/decline',
  )
  @Roles('WORKER')
  declineAppointment(
    @CurrentUser()
    user: any,

    @Param(
      'id',
      ParseUUIDPipe,
    )
    id: string,
  ) {
    return this.appointmentsService.declineAppointment(
      user.sub,
      id,
    );
  }
}