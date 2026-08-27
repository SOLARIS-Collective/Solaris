import { BooleanLike } from 'common/react';
import { useBackend } from '../backend';
import { Box, Button, Flex, Grid } from '../components';
import { Window } from '../layouts';

type Data = {
  input_code: string;
  locked: BooleanLike;
  lock_code: BooleanLike;
};

const NukeKeypad = (props, context) => {
  const { act } = useBackend(context);
  const keypadKeys = [
    ['1', '4', '7', 'C'],
    ['2', '5', '8', '0'],
    ['3', '6', '9', 'E'],
  ];
  return (
    <Flex justify="center" width="100%">
      <Box>
        <Grid>
          {keypadKeys.map((keyColumn) => (
            <Grid.Column key={keyColumn[0]}>
              {keyColumn.map((key) => (
                <Button
                  fluid
                  bold
                  key={key}
                  mb="6px"
                  content={key}
                  textAlign="center"
                  fontSize="40px"
                  lineHeight={1.25}
                  width="55px"
                  onClick={() => act('keypad', { digit: key })}
                />
              ))}
            </Grid.Column>
          ))}
        </Grid>
      </Box>
    </Flex>
  );
};

export const LockedSafe = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { input_code, locked, lock_code } = data;
  return (
    <Window width={300} height={400} theme="ntos">
      <Window.Content>
        <Box m="6px">
          <Box
            mb="6px"
            p="10px"
            backgroundColor="rgba(0,0,0,0.5)"
            textAlign="center"
            fontSize="24px"
            fontFamily="monospace"
          >
            {input_code}
          </Box>
          <Box
            mb="12px"
            p="10px"
            backgroundColor="rgba(0,0,0,0.5)"
            textAlign="center"
            fontSize="18px"
          >
            {!lock_code && 'No password set.'}
            {!!lock_code && (locked ? 'Locked' : 'Unlocked')}
          </Box>
          <NukeKeypad />
        </Box>
      </Window.Content>
    </Window>
  );
};
