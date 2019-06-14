exports._exit = function(code) {
  return function() {
    process.exit(code);
  };
};
