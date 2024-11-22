import {NDKEvent, NDKKind, NDKNip07Signer, NDKUser} from '@nostr-dev-kit/ndk';
import {useMutation} from '@tanstack/react-query';

import {useNostrContext} from '../../context';
import {useAuth} from '../../store';

export const useCreateCashuWallet = () => {
  const {ndk} = useNostrContext();
  const {publicKey, privateKey} = useAuth();

  return useMutation({
    mutationFn: async ({
      name,
      description,
      mints,
      relays,
      balance,
      privkey,
      unit = 'sat',
    }: {
      name: string;
      description?: string;
      mints: string[];
      relays?: string[];
      balance?: string;
      privkey?: string;
      unit?: string;
    }) => {
      const signer = new NDKNip07Signer();
      const user = new NDKUser({pubkey: publicKey});
      const content = await signer.nip44Encrypt(
        user,
        JSON.stringify([
          ['balance', balance || '0', unit],
          ['privkey', privkey || privateKey],
        ]),
      );

      const event = new NDKEvent(ndk);

      event.kind = NDKKind.CashuWallet;
      event.content = content;
      event.tags = [
        ['d', name.toLowerCase().replace(/\s+/g, '-')],
        ...mints.map((mint) => ['mint', mint]),
        ['name', name],
        ['unit', unit],
      ];

      if (description) event.tags.push(['description', description]);
      const eventRelays = relays?.length ? relays : ['wss://relay1', 'wss://relay2'];
      if (eventRelays.length) {
        relays.forEach((relay) => event.tags.push(['relay', relay]));
      }

      return await event.publish();
    },
  });
};
