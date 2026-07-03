{ ... }:

{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      manager = {
        ratio        = [ 1 3 4 ];
        sort_by      = "alphabetical";
        sort_dir_first = true;
        show_hidden  = false;
        show_symlink = true;
      };
    };
  };
}
