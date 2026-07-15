const delay = (ms, name) => new Promise(resolve => {
  setTimeout(() => {
    console.log(name, 'finished');
    resolve(name);
  }, ms);
});

async function run() {
  console.log('starting array');
  const arr = [
    await delay(100, 'first'),
    await delay(100, 'second')
  ];
  console.log('array:', arr);
}
run();
