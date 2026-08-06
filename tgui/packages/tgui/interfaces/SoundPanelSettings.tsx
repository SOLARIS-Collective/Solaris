import { useBackend } from '../backend';
import { Button, LabeledList, Section, Slider } from '../components';
import { Window } from '../layouts';

interface SoundVolumeData {
  sound_volume: Record<string, number>;
  playing_flag: number;
}

type SoundPanelSettingsProps = {};

export const SoundPanelSettings = (props: SoundPanelSettingsProps, context) => {
  const { act, data } = useBackend<SoundVolumeData>(context);
  const { sound_volume, playing_flag } = data;

  const soundFlagLabels: Record<string, string> = {
    '1': 'Общие',
    '2': 'Музыка в лобби',
    '4': 'Окружение',
    '8': 'Оружие',
    '16': 'Оповещения',
    '32': 'Музыкальные инструменты',
    '64': 'Музыкальный автомат',
    '128': 'Радио',
    '256': 'Молитвы',
    '512': 'Админские',
    '1024': 'Шум корабля',
    '2048': 'Конец раунда',
  };

  const flagKeys = Object.keys(sound_volume || {})
    .sort((a, b) => Number(a) - Number(b));

  return (
    <Window width={480} height={Math.min(flagKeys.length * 28 + 60, 600)} title="Настройки звука">
      <Window.Content>
        <Section title="">
          <LabeledList>
            {flagKeys.map((flag) => {
              const label = soundFlagLabels[flag];
              if (!label) return null;
              const vol = sound_volume[flag] ?? 0;
              return (
                <LabeledList.Item
                  key={flag}
                  label={label}
                  buttons={
                    <>
                      <Button
                        icon="play"
                        color={playing_flag === Number(flag) ? 'green' : 'transparent'}
                        tooltip="Тест"
                        onClick={() =>
                          act('test_sound', {
                            flag: Number(flag),
                          })
                        }
                      />
                      <Button
                        icon="stop-circle"
                        color="transparent"
                        tooltip="Стоп"
                        onClick={() =>
                          act('stop_sound', {})
                        }
                      />
                    </>
                  }
                >
                  <Slider
                    value={vol}
                    minValue={0}
                    maxValue={100}
                    step={1}
                    onChange={(e, value) =>
                      act('set_volume', { flag: Number(flag), volume: value })
                    }
                  />
                </LabeledList.Item>
              );
            })}
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
