import { NtosWindow } from '../layouts';
import { StockExchangeContent } from './StockExchange';

export const NtosStockTerminal = () => {
  return (
    <NtosWindow title="Frontier Exchange Terminal" width={900} height={650}>
      <NtosWindow.Content scrollable>
        <StockExchangeContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};