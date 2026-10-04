/* Exercise the cartridge in the official, free PICO-8 Education Edition.
 * Development dependencies: Playwright and Chromium. Product cart is unchanged;
 * GPIO telemetry is inserted into a temporary copy and removed on exit.
 */
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const assert = require('node:assert/strict');
const {chromium} = require('playwright');
const root = path.resolve(__dirname, '..');
const probe = `
function development_probe()
 poke(0x5f80,173)
 poke(0x5f81,phase=="title" and 0 or phase=="play" and 1 or 2)
 poke2(0x5f82,flr(hero.x))
 poke2(0x5f84,flr(hero.y))
 poke(0x5f86,hero.dash_t)
 poke(0x5f87,hero.cool)
 poke(0x5f88,hero.atk_t)
 poke(0x5f89,hero.ground and 1 or 0)
 local flags=0
 for i=1,3 do if gates[i].open then flags+=2^(i-1) end end
 poke(0x5f8a,flags)
 poke2(0x5f8b,tick)
 poke(0x5f8d,min(255,flr(stat(1)*100)))
end
`;
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'nero-pico-'));
const cartPath = path.join(tmp, 'nero-check.p8');
const source = fs.readFileSync(path.join(root, 'nero-fuori.p8'), 'utf8');
fs.writeFileSync(cartPath, source
  .replace('function _draw()\n', 'function _draw()\n development_probe()\n')
  .replace('\n__gfx__\n', probe + '\n__gfx__\n'));

(async () => {
 const proxy = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;
 const browser = await chromium.launch({
  headless:true,
  ...(process.env.CHROMIUM_PATH ? {executablePath:process.env.CHROMIUM_PATH} : {}),
  ...(proxy ? {proxy:{server:proxy}} : {}),
  args:['--no-sandbox']
 });
 try {
  const page = await browser.newPage({viewport:{width:800,height:800}});
  const state = () => page.evaluate(() => {
   const g=window.pico8_gpio;
   return {marker:g[0],phase:g[1],x:g[2]+256*g[3],y:g[4]+256*g[5],
    dash:g[6],cool:g[7],attack:g[8],ground:g[9],gates:g[10],
    frame:g[11]+256*g[12],cpu:g[13]};
  });
  const frames = async n => {
   const before=(await state()).frame;
   await page.waitForFunction(({before,n}) => {
    const g=window.pico8_gpio;
    return ((g[11]+g[12]*256-before+7200)%7200)>=n;
   }, {before,n}, {polling:'raf',timeout:5000});
  };
  const until = async condition => {
   for(let i=0;i<500;i++){
    const s=await state();
    if(condition(s)) return s;
    await frames(1);
   }
   throw new Error('Condition timed out: '+JSON.stringify(await state()));
  };
  const tap = async (key,n=2) => {
   await page.keyboard.down(key);await frames(n);
   await page.keyboard.up(key);await frames(2);
  };
  const save = async name => {
   await frames(1);
   const png=await page.locator('#canvas').evaluate(c=>{
    const output=document.createElement('canvas');
    output.width=output.height=512;
    const ctx=output.getContext('2d');
    ctx.imageSmoothingEnabled=false;
    ctx.drawImage(c,0,0,512,512);
    return output.toDataURL('image/png');
   });
   const output=path.join(root,'docs',name);
   fs.mkdirSync(path.dirname(output),{recursive:true});
   fs.writeFileSync(output,Buffer.from(png.split(',')[1],'base64'));
  };
  await page.goto('https://www.pico-8-edu.com/',{waitUntil:'domcontentloaded',timeout:60000});
  await page.locator('#p8_start_button').click();
  await page.waitForTimeout(4500);
  await page.locator('#p8_file_chooser').setInputFiles(cartPath);
  await page.waitForTimeout(2000);
  await page.locator('#canvas').click();
  await page.keyboard.type('run');await page.keyboard.press('Enter');
  await page.waitForFunction(()=>window.pico8_gpio?.[0]===173,null,{timeout:10000});
  assert.equal((await state()).phase,0);
  await save('title.png');
  await tap('z');
  assert.equal((await state()).phase,1);
  assert.equal((await state()).x,24);
  await save('preview.png');
  console.log('PASS: boot, title, start and captures at integer 4x scale');

  await page.keyboard.down('ArrowRight');
  await until(s=>s.x===101);
  await frames(35);
  assert.equal((await state()).x,101);
  assert.equal((await state()).cool,0);
  await page.keyboard.up('ArrowRight');await frames(2);
  await page.keyboard.down('ArrowDown');await tap('x');
  await page.keyboard.up('ArrowDown');await frames(20);
  assert.equal((await state()).gates,0);
  await tap('x');
  assert.equal((await state()).gates,1);
  await save('scratch.png');
  console.log('PASS: held direction does not auto-dash; vines require scratch');

  await page.keyboard.down('z');await frames(18);
  const jumpY=(await state()).y;
  assert(jumpY<90,'Full jump must have visible height');
  await page.keyboard.up('z');await until(s=>s.ground===1);
  await page.keyboard.down('ArrowRight');await until(s=>s.x===181);
  await page.keyboard.up('ArrowRight');await frames(3);
  await tap('x');await frames(14);
  assert.equal((await state()).gates,1);
  await page.keyboard.down('z');await frames(18);await page.keyboard.up('z');
  assert((await state()).y<88);
  await page.keyboard.down('ArrowDown');await tap('x');await page.keyboard.up('ArrowDown');
  assert.equal((await state()).gates,1,'Bite above crate must miss');
  await until(s=>s.ground===1);await frames(20);
  await page.keyboard.down('ArrowDown');await tap('x');await page.keyboard.up('ArrowDown');
  assert.equal((await state()).gates,3);
  console.log('PASS: jump, vertical attack bounds, crate requires grounded bite');

  await page.keyboard.down('ArrowRight');await until(s=>s.x===259);
  await frames(30);await page.keyboard.up('ArrowRight');await frames(3);
  await tap('x');await frames(15);
  assert.equal((await state()).gates,3);
  await tap('ArrowRight');
  await page.keyboard.down('ArrowRight');
  await until(s=>s.dash>0);
  assert.equal((await state()).gates,7);
  await save('dash.png');
  await until(s=>s.phase===2);await page.keyboard.up('ArrowRight');
  await save('finish.png');
  await frames(35);await tap('z');
  const result=await state();
  assert.equal(result.phase,1);assert.equal(result.gates,0);assert.equal(result.x,24);
  console.log('PASS: cardboard requires double tap dash; goal and restart');
  console.log(JSON.stringify({jumpY,final:result,renderer:'PICO-8 Education Edition'}));
 } finally {await browser.close();fs.rmSync(tmp,{recursive:true,force:true});}
})().catch(error=>{console.error(error);process.exitCode=1;});
