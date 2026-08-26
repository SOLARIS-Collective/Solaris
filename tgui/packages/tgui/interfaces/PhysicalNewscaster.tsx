import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, Section, LabeledList, Tabs } from '../components';

export const PhysicalNewscaster = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    scanned_user,
    security_mode,
    paper,
    channels = [],
    current_channel = {},
    channel_messages = [],
    messages = [],
    wanted = [],
    viewing_channel,
  } = data;

  return (
    <Window width={800} height={600}>
      <Window.Content scrollable>
        <Section
          title={`Newscaster - Пользователь: ${scanned_user || 'Unknown'}`}
        >
          <LabeledList>
            <LabeledList.Item label="Режим безопасности">
              {security_mode ? 'Да' : 'Нет'}
            </LabeledList.Item>
            <LabeledList.Item label="Бумага">{paper}</LabeledList.Item>
          </LabeledList>

          <Section title="Каналы">
            <Tabs>
              {wanted && wanted.filter((w) => w.active).length > 0 ? (
                <Tabs.Tab
                  color="red"
                  icon="skull-crossbones"
                  selected={viewing_channel === 'wanted'}
                  onClick={() =>
                    act('select_channel', { current_channel: 'wanted' })
                  }
                >
                  Розыск ({wanted.filter((w) => w.active).length})
                </Tabs.Tab>
              ) : null}
              {channels.map((channel, index) => (
                <Tabs.Tab
                  key={index}
                  selected={viewing_channel == channel.ID}
                  icon={channel.censored ? 'ban' : null}
                  textColor={channel.censored ? 'red' : 'white'}
                  onClick={() =>
                    act('select_channel', {
                      current_channel: channel.ID,
                    })
                  }
                >
                  {channel.name}
                </Tabs.Tab>
              ))}
              <Tabs.Tab color="green" onClick={() => act('create_channel')}>
                Создать канал [+]
              </Tabs.Tab>
            </Tabs>
          </Section>

          <Section
            title={
              current_channel.name
                ? `Канал: ${current_channel.name}`
                : viewing_channel === 'wanted'
                  ? 'Розыск'
                  : 'Новости'
            }
          >
            {current_channel.name ? (
              <>
                <Box
                  mb={2}
                  p={1}
                  backgroundColor="rgba(0,100,200,0.2)"
                  style={{
                    wordBreak: 'break-word',
                    overflowWrap: 'break-word',
                    whiteSpace: 'pre-wrap',
                  }}
                >
                  <Box bold>{current_channel.name}</Box>
                  <Box italic>{current_channel.desc}</Box>
                  <Box fontSize="0.8em">
                    Автор канала: {current_channel.author}
                  </Box>
                  {current_channel.locked ? (
                    <Box color="orange">Приватный канал</Box>
                  ) : null}
                  {current_channel.censored ? (
                    <Box color="red">Канал заблокирован</Box>
                  ) : null}
                </Box>
                {!current_channel.censored &&
                  (!current_channel.locked ||
                    current_channel.author === scanned_user) ? (
                    <Button
                      icon="edit"
                      color="blue"
                      mb={2}
                      onClick={() =>
                        act('create_story', {
                          channel_id: current_channel.ID,
                        })
                      }
                    >
                      Опубликовать новость
                    </Button>
                  ) : null}
                {channel_messages && channel_messages.length > 0 ? (
                  channel_messages.map((message, index) => (
                    <Box
                      key={index}
                      mb={2}
                      p={1}
                      backgroundColor="rgba(255,255,255,0.1)"
                      style={{
                        wordBreak: 'break-word',
                        overflowWrap: 'break-word',
                        whiteSpace: 'pre-wrap',
                      }}
                    >
                      <Box bold mb={1}>
                        Новость от {message.author}
                      </Box>
                      <Box mb={1}>{message.body}</Box>
                      <Box italic fontSize="0.8em" mb={1}>
                        Опубликовано: {message.time}
                      </Box>

                      {message.comments && message.comments.length > 0 ? (
                        <Box
                          mt={1}
                          p={1}
                          backgroundColor="rgba(100,100,100,0.2)"
                        >
                          <Box bold fontSize="0.9em" mb={1}>
                            Комментарии:
                          </Box>
                          {message.comments.map((comment, cIndex) => (
                            <Box key={cIndex} mb={1} pl={1}>
                              <Box fontSize="0.8em" italic>
                                {comment.author} ({comment.time}):
                              </Box>
                              <Box fontSize="0.9em">{comment.body}</Box>
                            </Box>
                          ))}
                        </Box>
                      ) : null}

                      <Box mt={1}>
                        <Button
                          icon="thumbs-up"
                          size="small"
                          color={message.user_liked ? 'green' : 'grey'}
                          onClick={() =>
                            act('like_message', {
                              message_id: message.ID,
                            })
                          }
                        >
                          {` ${message.likes || 0}`}
                        </Button>
                        <Button
                          icon="thumbs-down"
                          size="small"
                          color={message.user_disliked ? 'red' : 'grey'}
                          ml={1}
                          onClick={() =>
                            act('dislike_message', {
                              message_id: message.ID,
                            })
                          }
                        >
                          {` ${message.dislikes || 0}`}
                        </Button>
                        {!message.locked ? (
                          <Button
                            icon="comment"
                            size="small"
                            ml={1}
                            onClick={() =>
                              act('add_comment', {
                                message_id: message.ID,
                              })
                            }
                          >
                            Оставить комментарий
                          </Button>
                        ) : null}
                      </Box>
                    </Box>
                  ))
                ) : (
                  <Box>В этом канале пока нет новостей</Box>
                )}
              </>
            ) : viewing_channel === 'wanted' ? (
              <>
                {wanted &&
                  wanted.map((w, index) => (
                    <Box
                      key={index}
                      mb={2}
                      p={1}
                      backgroundColor={
                        w.active ? 'darkred' : 'rgba(100,100,100,0.5)'
                      }
                      opacity={w.active ? 1 : 0.7}
                      style={{
                        wordBreak: 'break-word',
                        overflowWrap: 'break-word',
                        whiteSpace: 'pre-wrap',
                      }}
                    >
                      <Box bold color={w.active ? 'red' : 'grey'}>
                        {w.active ? 'АКТИВНЫЙ РОЗЫСК' : 'ОТМЕНЕННЫЙ РОЗЫСК'} #
                        {w.ID}
                      </Box>
                      <Box bold color={w.active ? 'white' : 'grey'}>
                        Преступник: {w.criminal}
                      </Box>
                      <Box color={w.active ? 'white' : 'grey'}>
                        Преступление: {w.crime}
                      </Box>
                      <Box italic color={w.active ? 'white' : 'grey'}>
                        Опубликовано: {w.author}
                      </Box>
                      {security_mode && w.active ? (
                        <Button
                          icon="times"
                          color="red"
                          size="small"
                          mt={1}
                          onClick={() =>
                            act('clear_wanted', { wanted_id: w.ID })
                          }
                        >
                          Отменить этот розыск
                        </Button>
                      ) : null}
                    </Box>
                  ))}
                {(!wanted || !wanted.length) ? <Box>Нет розысков</Box> : null}
              </>
            ) : (
              <Box>Выберите канал для просмотра новостей</Box>
            )}
          </Section>

          <Box>
            <Button
              icon="print"
              disabled={!paper || paper <= 0}
              onClick={() => act('print_newspaper')}
            >
              Печать газеты ({paper})
            </Button>
            {security_mode ? (
              <>
                <Button
                  icon="search"
                  color="red"
                  onClick={() => act('create_wanted')}
                >
                  Объявить в розыск
                </Button>
                {wanted && wanted.filter((w) => w.active).length > 0 ? (
                  <Button
                    icon="times"
                    color="red"
                    onClick={() => act('clear_wanted')}
                  >
                    Отменить все розыски
                  </Button>
                ) : null}
              </>
            ) : null}
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
