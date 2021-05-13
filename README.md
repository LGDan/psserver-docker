# PSServer v3

PSServer v3 is a basic framework of powershell, nginx, pandoc, and fcgi, enabling the use of powershell as CGI scripts with pandoc for on-the-fly html generation.
It's now containerised, and based on alpine linux.

**This system has zero security by default, and by intent.**
 - I do not suggest running this on an open public IP unless you have it behind an authenticated reverse proxy. 
 - The Default nginx config is also very open by default. I suggest you add some deny entries.
 - It's down to you to handle authentication and authorisation.

# Usage

I haven't yet stuck this on Dockerhub, but it's pretty easy to build yourself.

1. Ensure you have docker installed.
2. Clone the project with `git clone https://github.com/LGDan/psserver-docker.git`
3. Enter the directory `cd psserver-docker`
4. Add your own scripts to `cgi-bin` or modify my existing ones.
5. Build the container: `docker build . --tag YourHandle/psserver:latest`
6. Run the container:
```
docker run -d \
    -e TZ=Europe/London \
    --restart unless-stopped \
    --name psserver \
    -p 80:80 \
    YourHandle/psserver:latest
```

There's a few ways you could use this container.

- As a build base for a larger powershell-based API
- As an API Proxy to simplify calls, hide API keys, or cache responses
- As an API based markup language converter

# History

## What was v1?

PSServer was a concept I had about being able to drop powershell script files (.ps1) in to a directory and have RESTful APIs (and documentation) automatically be generated based on the function definitions within the scripts. This was originally implmented with a `[Net.HttpListener]` running single threaded with a `.GetContext()` for handling requests and responses. This had the major drawback of only being able to run one operation at a time. With longer running powershell operations, this would hang the server while the request was completed, and made the system unusable for all but one person.

### v1 Improvements

- Token based authentication system
- AD Authentication system and AD group based authentication per method
- JSON used to govern permissions and rate limits

Powershell has issues trying to use certain native aspects of .Net, notably Async operations using the threadpool. For this reason, the `.BeginGetContext()` method of the original `[Net.HttpListener]` implementation was nonfunctional. To get round this, the system's main entry point was redesigned for v2.

## What was v2?

v2 Built on v1 by removing the `[Net.HttpListener]` from the original powershell system, and moving it to a Wrapper executable written in VB.NET that was able to fully utilise the Async operations, enabling multiple long running requests to be served concurrently. Wrapping the powershell with this new program brought its own new set of problems and benefits.

The main drawback was that garbage collection in powershell is very finnicky. Although it's based on .Net, the way objects are stored in powershell (especially globals) is designed in such a way that the program is meant to run, do what it needs to do, then terminate, freeing up it's memory at the end. This is an issue if you never intend to terminate the process.

### v2 Improvements

- Multi Threading and Async works properly.
- Easier accessibility to .Net methods and nuget packages through the wrapper meant Oauth and JWT was easy to implement and pass to the underlying powershell scripts.
- Certain frequently used methods could be compiled in to CLR with the wrapper exe, removing the need for JIT and increasing performance 9-12x in some functions.
- Implemented a simple LFU cache within the wrapper for powershell methods that returned json that did not change often. This increased performance 100x (12s down to 12ms) in some functions.

The codebase was starting to get heavy at this point, and it was not easy to add new functionality due to various dependency loops between the wrapper system and the underlying powershell scripts. It also constrained how scripts were written, as the object passed to them by the wrapper started to become this big monolithic beast of methods. This was where the original idea of 'drop an existing script in a folder' started to break down. Either significant refactoring was required, or a rewrite. At this point, I realised that there was no real framework that PSServer was based on that gave it the core (and unchanging) requirements. Rewrite it is. v3 begins.
