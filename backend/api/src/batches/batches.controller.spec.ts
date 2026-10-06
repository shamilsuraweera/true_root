import { BatchesController } from './batches.controller';
import { BatchesService } from './batches.service';

describe('BatchesController', () => {
  const createBatch = jest.fn();
  const listBatches = jest.fn();
  const getBatch = jest.fn();
  const changeQuantity = jest.fn();
  const changeStatus = jest.fn();
  const changeStage = jest.fn();
  const splitBatch = jest.fn();
  const mergeBatches = jest.fn();
  const transformBatch = jest.fn();

  const mockService = {
    createBatch,
    listBatches,
    getBatch,
    changeQuantity,
    changeStatus,
    changeStage,
    splitBatch,
    mergeBatches,
    transformBatch,
  } as unknown as BatchesService;

  const controller = new BatchesController(mockService);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('delegates create to service', async () => {
    const dto = {
      productId: 1,
      quantity: 50.5,
      grade: 'Grade A',
      ownerId: 2,
      stageId: 3,
      unit: 'kg',
    };
    await controller.create(dto);
    expect(createBatch).toHaveBeenCalledWith(1, 50.5, 'Grade A', 2, 3, 'kg');
  });

  it('delegates get to service', async () => {
    await controller.get('123');
    expect(getBatch).toHaveBeenCalledWith(123);
  });

  it('delegates changeQuantity to service', async () => {
    await controller.changeQuantity('5', { quantity: 75.2 });
    expect(changeQuantity).toHaveBeenCalledWith(5, 75.2);
  });

  it('delegates split to service', async () => {
    const splitDto = {
      items: [
        { quantity: 20, grade: 'A' },
        { quantity: 30, grade: 'B' },
      ],
    };
    await controller.split('10', splitDto);
    expect(splitBatch).toHaveBeenCalledWith(10, splitDto.items);
  });
});

