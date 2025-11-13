// 完整的40格棋盘数据
export const boardData = [
  { position: 0, type: 'start', name: '起点', effect: '经过+200' },
  { position: 1, type: 'property', name: '地中海大道', price: 60, color: 'brown', rent: [2, 10, 30, 90, 160, 250] },
  { position: 2, type: 'community-chest', name: '社区基金', effect: '抽卡' },
  { position: 3, type: 'property', name: '波罗的海大道', price: 60, color: 'brown', rent: [4, 20, 60, 180, 320, 450] },
  { position: 4, type: 'tax', name: '所得税', effect: '支付200' },
  { position: 5, type: 'railroad', name: '铁路1', price: 200, rent: [25, 50, 100, 200] },
  { position: 6, type: 'property', name: '东方大道', price: 100, color: 'light-blue', rent: [6, 30, 90, 270, 400, 550] },
  { position: 7, type: 'chance', name: '机会', effect: '抽卡' },
  { position: 8, type: 'property', name: '佛蒙特大道', price: 100, color: 'light-blue', rent: [6, 30, 90, 270, 400, 550] },
  { position: 9, type: 'property', name: '康涅狄格大道', price: 120, color: 'light-blue', rent: [8, 40, 100, 300, 450, 600] },
  { position: 10, type: 'jail', name: '监狱', effect: '停留' },
  { position: 11, type: 'property', name: '圣查尔斯大道', price: 140, color: 'pink', rent: [10, 50, 150, 450, 625, 750] },
  { position: 12, type: 'utility', name: '电力公司', price: 150, rent: [4, 10] },
  { position: 13, type: 'property', name: '州立大道', price: 140, color: 'pink', rent: [10, 50, 150, 450, 625, 750] },
  { position: 14, type: 'property', name: '弗吉尼亚大道', price: 160, color: 'pink', rent: [12, 60, 180, 500, 700, 900] },
  { position: 15, type: 'railroad', name: '铁路2', price: 200, rent: [25, 50, 100, 200] },
  { position: 16, type: 'property', name: '圣詹姆斯大道', price: 180, color: 'orange', rent: [14, 70, 200, 550, 750, 950] },
  { position: 17, type: 'community-chest', name: '社区基金', effect: '抽卡' },
  { position: 18, type: 'property', name: '田纳西大道', price: 180, color: 'orange', rent: [14, 70, 200, 550, 750, 950] },
  { position: 19, type: 'property', name: '纽约大道', price: 200, color: 'orange', rent: [16, 80, 220, 600, 800, 1000] },
  { position: 20, type: 'free-parking', name: '免费停车', effect: '安全区' },
  { position: 21, type: 'property', name: '肯塔基大道', price: 220, color: 'red', rent: [18, 90, 250, 700, 875, 1050] },
  { position: 22, type: 'chance', name: '机会', effect: '抽卡' },
  { position: 23, type: 'property', name: '印第安纳大道', price: 220, color: 'red', rent: [18, 90, 250, 700, 875, 1050] },
  { position: 24, type: 'property', name: '伊利诺伊大道', price: 240, color: 'red', rent: [20, 100, 300, 750, 925, 1100] },
  { position: 25, type: 'railroad', name: '铁路3', price: 200, rent: [25, 50, 100, 200] },
  { position: 26, type: 'property', name: '大西洋大道', price: 260, color: 'yellow', rent: [22, 110, 330, 800, 975, 1150] },
  { position: 27, type: 'property', name: '文特诺大道', price: 260, color: 'yellow', rent: [22, 110, 330, 800, 975, 1150] },
  { position: 28, type: 'utility', name: '自来水公司', price: 150, rent: [4, 10] },
  { position: 29, type: 'property', name: '马文花园', price: 280, color: 'yellow', rent: [24, 120, 360, 850, 1025, 1200] },
  { position: 30, type: 'go-to-jail', name: '入狱', effect: '直接入狱' },
  { position: 31, type: 'property', name: '太平洋大道', price: 300, color: 'green', rent: [26, 130, 390, 900, 1100, 1275] },
  { position: 32, type: 'property', name: '北卡罗来纳大道', price: 300, color: 'green', rent: [26, 130, 390, 900, 1100, 1275] },
  { position: 33, type: 'community-chest', name: '社区基金', effect: '抽卡' },
  { position: 34, type: 'property', name: '宾夕法尼亚大道', price: 320, color: 'green', rent: [28, 150, 450, 1000, 1200, 1400] },
  { position: 35, type: 'railroad', name: '铁路4', price: 200, rent: [25, 50, 100, 200] },
  { position: 36, type: 'chance', name: '机会', effect: '抽卡' },
  { position: 37, type: 'property', name: '公园广场', price: 350, color: 'dark-blue', rent: [35, 175, 500, 1100, 1300, 1500] },
  { position: 38, type: 'tax', name: '奢侈品税', effect: '支付100' },
  { position: 39, type: 'property', name: '木板路', price: 400, color: 'dark-blue', rent: [50, 200, 600, 1400, 1700, 2000] }
]

// 获取格子颜色类名
export const getTileColorClass = (tile) => {
  if (!tile.color) return ''
  return `color-${tile.color.replace(' ', '-')}`
}

// 获取租金
export const getRent = (tile, houseCount = 0) => {
  if (!tile.rent) return 0
  return tile.rent[Math.min(houseCount, tile.rent.length - 1)]
}