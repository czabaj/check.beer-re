import { jest } from "@jest/globals";

const sendEachForMulticast = jest.fn();

export const getMessaging = () => ({
  sendEachForMulticast,
});
