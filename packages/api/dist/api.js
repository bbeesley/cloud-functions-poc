export async function handler(request, response) {
    console.info({ request });
    response.send({ ok: true });
}
