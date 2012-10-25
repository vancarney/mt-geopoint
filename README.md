Developer Installation
==
 
Build Dependancies
--
 <p>The following libries and/or languages must be installed on the system:</p>
 * [NodeJS](http://nodejs.org/)
 * [PEAK](http://peak.telecommunity.com/)
 * [Ruby on Rails](http://rubyonrails.org/) ([rvm](https://rvm.io/) makes installation easy)
 * [Ruby Gems](http://rubygems.org/)
 
Node Package Modules
--
 <p>sources require the use of the following NPMs.
 These NPMs can be installed by the included shell script in the util folder
 <p><code>sudo util/setup.sh</code></p>
 </p>
 
 * [Coffeescript](http://coffeescript.org/)
 * [Coffeelint](http://www.coffeelint.org/)
 * [Mocha](http://visionmedia.github.com/mocha/)
 * [docco.coffee](http://jashkenas.github.com/docco/)
 * [jsdom](https://github.com/tmpvar/jsdom)
 * [uglify-js](https://github.com/mishoo/UglifyJS)

Ruby Gems
--
<p> Sass and Markdown require that their respedtive Ruby Gems be installed on your system </p>
<b>Install Sass</b>
<p><code>gem install sass</code>
</p>

<b>Install Compass</b>
<p><code>gem install compass</code>
</p>

<b>Install Markdown</b>
<p><code>gem install markdown</code>
</p>

Build Tools
--
<p>The Cakefile provides several buildtools for convenience functions.
typings <code>cake</code> in the project directory root will provide the following help contents:</p>
<p>Cakefile defines the following tasks:</b>
<p>
<b>cake docs</b>              	   # generate documentation<br/>
<b>cake build</b>                  # compile source<br/>
<b>cake watch</b>                  # watch src folders and compile on file chang<br/>
<b>cake minify</b>                 # minify js files in build/js dir<br/>
<b>cake readme</b>                 # generate readme.html in root project dir<br/>
<b>cake test</b>                   # run tests (not really)<br/>
<b>cake clean</b>                  # clean generated files<br/>
</p>