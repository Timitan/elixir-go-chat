import java.net.*;
import java.io.*;

class ChatClient {
    public static void main(String... args) throws IOException{
        Socket s = null;

        String host = "localhost";
        int port = 6666;
        if(args.length == 1) {
            host = args[0];
        } else if(args.length == 2) {
            host = args[0];
            port = Integer.parseInt(args[1]);
        }

        try {
            s = new Socket(host, port);
            var in = new BufferedReader(new InputStreamReader(s.getInputStream()));
            var out = new PrintWriter(new OutputStreamWriter(s.getOutputStream()), true); // true = autoflush
            var stdin = new BufferedReader(new InputStreamReader(System.in));

            new Thread(() -> {
                try {
                    String reply;
                    while (true) {
                        if ((reply = in.readLine()) == null) {
                            break;
                        }
                        System.out.println(reply);
                        System.out.print("> ");
                    }
                } catch (Exception e) {
                    System.out.println("Reading stopped.");
                }
            }).start();

            String line;
            while(true) {
                System.out.print("> ");
                if ((line = stdin.readLine()) == null) {
                    break;
                }
                out.println(line);
            }
        } catch (IOException e) {
            System.out.println("Error: Chat server is not running!");
        } finally {
            System.out.println("Connection closed!");
            s.close();
        }
    }
}
