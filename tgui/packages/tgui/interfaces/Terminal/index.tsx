/**
 * @file
 * @copyright 2022-2023
 * @author Original skeletonman0 (https://github.com/skeletonman0/)
 * @author Changes garash2k (https://github.com/garash2l)
 * @license MIT
 */

import { Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { InputAndButtonsSection } from './InputAndButtonsSection';
import { PheripheralsSection } from './PheripheralsSection';
import { TerminalOutputSection } from './TerminalOutputSection';
import { TerminalData } from './types';

export const Terminal = () => {
  const { data } = useBackend<TerminalData>();
  const { windowName, displayHTML } = data;

  return (
    <Window theme="retro-dark" title={windowName} width={380} height={350}>
      <Window.Content fontFamily="Consolas">
        <Stack vertical fill>
          <Stack.Item grow>
            <TerminalOutputSection displayHTML={displayHTML} />
          </Stack.Item>
          <Stack.Item>
            <InputAndButtonsSection />
          </Stack.Item>
          <Stack.Item>
            <PheripheralsSection />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
