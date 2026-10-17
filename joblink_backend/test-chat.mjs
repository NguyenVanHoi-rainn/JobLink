import { io } from 'socket.io-client';

const workerToken = process.env.WORKER_TOKEN;
const employerToken = process.env.EMPLOYER_TOKEN;
const conversationId = process.env.CONVERSATION_ID;

if (!workerToken || !employerToken || !conversationId) {
  console.error('Thiếu token hoặc conversationId');
  process.exit(1);
}

const workerSocket = io(
  'http://localhost:3000/chat',
  {
    auth: {
      token: workerToken,
    },
  },
);

const employerSocket = io(
  'http://localhost:3000/chat',
  {
    auth: {
      token: employerToken,
    },
  },
);

let workerJoined = false;
let employerJoined = false;

function trySend() {
  if (!workerJoined || !employerJoined) {
    return;
  }

  console.log('');
  console.log('Cả 2 đã join room.');
  console.log('Worker gửi realtime...');

  workerSocket.emit(
    'sendMessage',
    {
      conversationId,
      content: 'Test realtime lan 2',
      messageType: 'TEXT',
    },
    (response) => {
      console.log('Worker ACK:', response);
    },
  );
}

workerSocket.on('connect', () => {
  console.log(
    'Worker connected:',
    workerSocket.id,
  );

  workerSocket.emit(
    'joinConversation',
    {
      conversationId,
    },
    (response) => {
      console.log(
        'Worker join:',
        response,
      );

      workerJoined = true;
      trySend();
    },
  );
});

employerSocket.on('connect', () => {
  console.log(
    'Employer connected:',
    employerSocket.id,
  );

  employerSocket.emit(
    'joinConversation',
    {
      conversationId,
    },
    (response) => {
      console.log(
        'Employer join:',
        response,
      );

      employerJoined = true;
      trySend();
    },
  );
});

employerSocket.on(
  'newMessage',
  (message) => {
    console.log('');
    console.log(
      ' Employer nhận realtime:',
    );

    console.log(message);

    setTimeout(() => {
      workerSocket.disconnect();
      employerSocket.disconnect();
      process.exit(0);
    }, 500);
  },
);

workerSocket.on(
  'connect_error',
  (error) => {
    console.error(
      'Worker error:',
      error.message,
    );
  },
);

employerSocket.on(
  'connect_error',
  (error) => {
    console.error(
      'Employer error:',
      error.message,
    );
  },
);