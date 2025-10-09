{ ... }:
{
  services.xremap = {
    config = {
      modmap = [
        {
          # CapsLockをCtrlに置換
          name = "Swap left Ctrl and CapsLock";
          remap = {
            CapsLock = "Ctrl_L";
            Ctrl_L = "CapsLock";
          };
        }
      ];
    };
  };
}

