// http://www.boost.org/doc/libs/1_63_0/libs/convert/doc/html/boost_convert/getting_started.html

#include <boost/convert.hpp>
#include <boost/convert/lexical_cast.hpp>

using std::string;
using boost::lexical_cast;
using boost::convert;

// Definition of the default converter (optional)
struct boost::cnv::by_default : public boost::cnv::lexical_cast {};

int main()
{
try
{
    boost::cnv::lexical_cast cnv; // boost::lexical_cast-based converter

    int    i1 = lexical_cast<int>("123");          // boost::lexical_cast standard deployment
    int    i2 = convert<int>("123").value();       // boost::convert with the default converter
    int    i3 = convert<int>("123", cnv).value();  // boost::convert with an explicit converter
    string s1 = lexical_cast<string>(123);         // boost::lexical_cast standard deployment
    string s2 = convert<string>(123).value();      // boost::convert with the default converter
    string s3 = convert<string>(123, cnv).value(); // boost::convert with an explicit converter
}
catch (std::exception const& ex)
{
}
}
