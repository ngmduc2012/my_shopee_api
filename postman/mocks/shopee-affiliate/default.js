const http = require('http');
// Local-only stand-in using the official envelope and fields, not a live offer.
// Fixture data and credentials are deliberately fictional/public documentation data.
http.createServer(async (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  if (req.method !== 'POST' || req.url !== '/graphql') {
    res.statusCode = 501;
    return res.end(JSON.stringify({error: 'Endpoint not modeled'}));
  }
  const chunks = [];
  let body = req.body;
  if (!body) {
    for await (const chunk of req) chunks.push(chunk);
    try { body = JSON.parse(Buffer.concat(chunks).toString()); }
    catch (_) { res.statusCode = 400; return res.end('{}'); }
  }
  if (typeof body === 'string') body = JSON.parse(body);
  const query = body.query;
  if (typeof query !== 'string') { res.statusCode = 400; return res.end('{}'); }
  if (query.includes('itemId: 9504')) await new Promise(r => setTimeout(r, 2500));
  if (query.includes('itemId: 9503')) { res.statusCode = 503; return res.end('<html>busy</html>'); }
  if (query.includes('itemId: 9429')) { res.statusCode = 429; return res.end('{}'); }
  if (query.includes('__timeout__')) await new Promise(r => setTimeout(r, 2500));
  if (query.includes('__http_503__')) {
    res.statusCode = 503; return res.end(JSON.stringify({error:'busy'}));
  }
  if (query.includes('__invalid_json__')) return res.end('<html>proxy failure</html>');
  if (query.includes('__rate_limit__')) return res.end(JSON.stringify({
    errors:[{message:'Rate limit exceeded',extensions:{code:10030}}],data:null,
  }));
  if (query.includes('productOfferV2(')) return res.end(JSON.stringify({data:{productOfferV2:{
    nodes:[{itemId:2,shopId:1,productName:'Sản phẩm giả lập',imageUrl:'https://example.com/product.jpg',
      priceMin:'100000',priceMax:'120000',shopName:'Demo',productLink:'https://shopee.vn/product/1/2',
      offerLink:'https://s.shopee.vn/demo',commissionRate:'0.05',sales:10,ratingStar:'4.5'}],
    pageInfo:{page:1,limit:20,hasNextPage:false},
  }}}));
  if (query.includes('generateShortLink(input:')) return res.end(JSON.stringify({
    data:{generateShortLink:{shortLink:'https://s.shopee.vn/demo'}},
  }));
  res.statusCode = 501; res.end(JSON.stringify({error:'Operation not modeled'}));
}).listen(process.env.PORT || 4908);
